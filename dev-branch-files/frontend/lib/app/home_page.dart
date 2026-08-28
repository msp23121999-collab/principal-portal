import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErpHomePage extends StatelessWidget {
  const ErpHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00102B), Color(0xFF001B44), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand & Header Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _fade(const Color(0xFFFFB800), 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 36,
                        color: Color(0xFF001B44),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'KSRCE ERP — Campus OS',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Unified Enterprise College Management System',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8DA4CE)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your operational portal to access your dashboard',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Portal Selection Wrap Cards
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildPortalCard(
                          context,
                          title: 'Super Admin Portal',
                          subtitle:
                              'System Settings, RBAC Matrix, Security, Gateway & Audit Logs',
                          icon: Icons.shield_outlined,
                          badge: 'SYSTEM CONTROL',
                          color: const Color(0xFFFFB800),
                          route: '/superadmin',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'ERP Admin Portal',
                          subtitle:
                              'Academics, Students, Faculty, Exams, HR, Finance & Services',
                          icon: Icons.admin_panel_settings_rounded,
                          badge: 'OPERATIONS CONTROL',
                          color: const Color(0xFF0052CC),
                          route: '/admin',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'HOD Portal',
                          subtitle:
                              'Department KPI Analytics, Faculty Allocation & Approvals',
                          icon: Icons.badge_outlined,
                          badge: 'DEPARTMENT CHAIR',
                          color: const Color(0xFF8B5CF6),
                          route: '/hod',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'Dean Portal',
                          subtitle:
                              'Academic Governance, Quality Assurance, Curriculum & Compliance',
                          icon: Icons.verified_rounded,
                          badge: 'ACADEMIC LEADERSHIP',
                          color: const Color(0xFF0EA5E9),
                          route: '/dean',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'Principal Portal',
                          subtitle:
                              'Institution Head: Strategy, Safety, Administration & Stakeholder Relations',
                          icon: Icons.account_balance_rounded,
                          badge: 'INSTITUTION HEAD',
                          color: const Color(0xFFF97316),
                          route: '/principal',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'Faculty Portal',
                          subtitle:
                              'Attendance, Marks Entry, Lesson Plans & Workload',
                          icon: Icons.person_search_outlined,
                          badge: 'TEACHING FACULTY',
                          color: const Color(0xFF16A34A),
                          route: '/faculty',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'Student Portal',
                          subtitle:
                              'Academic Calendar, Attendance, Fees, Hall Ticket & Results',
                          icon: Icons.school_outlined,
                          badge: 'STUDENT SELF-SERVICE',
                          color: const Color(0xFF06B6D4),
                          route: '/student',
                        ),
                        _buildPortalCard(
                          context,
                          title: 'Parent Portal',
                          subtitle:
                              'Attendance, academic progress, fees, notices, and child communication',
                          icon: Icons.family_restroom_rounded,
                          badge: 'PARENT ACCESS',
                          color: const Color(0xFF22C55E),
                          route: '/parent',
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    const Text(
                      'KSR College of Engineering • Enterprise ERP v1.0 • All Modules Operational',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color color,
    required String route,
  }) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF0C192E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fade(color, 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _fade(color, 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _fade(color, 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _fade(color, 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Access Portal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _fade(Color color, double opacity) {
    return color.withAlpha((255 * opacity).round());
  }
}
