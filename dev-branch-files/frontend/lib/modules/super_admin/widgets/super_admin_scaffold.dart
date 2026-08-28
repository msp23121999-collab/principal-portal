import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../admin/app/router/route_names.dart';
import '../../admin/app/theme/app_colors.dart';
import '../../admin/widgets/module_preloader.dart';
import 'super_admin_drawer.dart';

class SuperAdminScaffold extends StatefulWidget {
  final String currentLocation;
  final Widget child;

  const SuperAdminScaffold({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  @override
  State<SuperAdminScaffold> createState() => _SuperAdminScaffoldState();
}

class _SuperAdminScaffoldState extends State<SuperAdminScaffold> {
  bool _isSidebarVisible = true;
  bool _showPreloader = true;

  @override
  Widget build(BuildContext context) {
    if (_showPreloader) {
      return ModulePreloader(
        moduleName: 'Super Admin System Control',
        moduleSubtitle: 'KSRCE ERP Full System Access · RBAC Level 10',
        icon: Icons.shield_rounded,
        accentColor: const Color(0xFFFFB800),
        badge: 'SYSTEM CONTROL',
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showPreloader = false);
            });
            return const SizedBox.shrink();
          },
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.darkBlue,
            border: Border(
              bottom: BorderSide(color: Color(0xFF002247), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () {
                      if (isMobile) {
                        Scaffold.of(context).openDrawer();
                      } else {
                        setState(() {
                          _isSidebarVisible = !_isSidebarVisible;
                        });
                      }
                    },
                    icon: Icon(
                      _isSidebarVisible && !isMobile
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Toggle Navigation',
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SUPER ADMIN SYSTEM CONTROL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'settings') {
                      context.go(RouteNames.systemSettings);
                    } else if (value == 'roles') {
                      context.go(RouteNames.rolesPermissions);
                    } else if (value == 'logout') {
                      context.go('/');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Logged out from Super Admin Portal. Returned to Portal Gateway.',
                          ),
                          backgroundColor: Color(0xFF0052CC),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Administrator',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'superadmin@ksrce.ac.in',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Divider(),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'System Settings',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'roles',
                      child: Row(
                        children: [
                          Icon(Icons.security_outlined, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Roles & Permissions Matrix',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB800),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'SA',
                          style: TextStyle(
                            color: Color(0xFF00102B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Root Access Level 10',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFFFFB800),
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: isMobile
          ? SuperAdminDrawer(currentLocation: widget.currentLocation)
          : null,
      body: Row(
        children: [
          if (!isMobile && _isSidebarVisible)
            SuperAdminDrawer(currentLocation: widget.currentLocation),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
