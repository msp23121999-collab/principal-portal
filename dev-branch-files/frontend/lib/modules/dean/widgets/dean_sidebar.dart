import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_state.dart';

class DeanSidebar extends StatelessWidget {
  const DeanSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        final selectedIndex = appState.selectedNavIndex;

        return Container(
          width: 260,
          color: DeanTheme.primaryNavy,
          child: Column(
            children: [
              // Brand Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                color: DeanTheme.darkNavyHeader,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DeanTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Campus OS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Dean Portal',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: DeanTheme.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Menu Items (Clean Titles without numbers)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  children: [
                    // Dashboard
                    _buildNavItem(context, 0, 'Dashboard', Icons.home_filled, selectedIndex),

                    const SizedBox(height: 12),
                    _buildSectionHeader('ACADEMIC OVERVIEW'),
                    _buildNavItem(context, 1, 'Academic Overview', Icons.dashboard_outlined, selectedIndex),

                    const SizedBox(height: 12),
                    _buildSectionHeader('ACADEMIC MANAGEMENT'),
                    _buildNavItem(context, 2, 'Curriculum & Regulations', Icons.menu_book_outlined, selectedIndex),
                    _buildNavItem(context, 3, 'Programme & Course', Icons.apps_outlined, selectedIndex),
                    _buildNavItem(context, 4, 'Faculty Performance', Icons.people_outline, selectedIndex),
                    _buildNavItem(context, 5, 'Student Performance', Icons.person_outline, selectedIndex),
                    _buildNavItem(context, 6, 'Attendance Analytics', Icons.analytics_outlined, selectedIndex),
                    _buildNavItem(context, 7, 'Examination Management', Icons.fact_check_outlined, selectedIndex),
                    _buildNavItem(context, 8, 'Lesson Plan Monitoring', Icons.assignment_outlined, selectedIndex),
                    _buildNavItem(context, 9, 'CO-PO Attainment', Icons.alt_route_outlined, selectedIndex),
                    _buildNavItem(context, 10, 'Research & Innovation', Icons.science_outlined, selectedIndex),

                    const SizedBox(height: 12),
                    _buildSectionHeader('QUALITY ASSURANCE'),
                    _buildNavItem(context, 11, 'Accreditation & QA', Icons.verified_outlined, selectedIndex),
                    _buildNavItem(context, 12, 'Calendar & Events', Icons.calendar_month_outlined, selectedIndex),
                    _buildNavItem(context, 13, 'Academic Approvals', Icons.approval_outlined, selectedIndex),

                    const SizedBox(height: 12),
                    _buildSectionHeader('REPORTS & BENCHMARKING'),
                    _buildNavItem(context, 14, 'Reports & Analytics', Icons.bar_chart_outlined, selectedIndex),
                    _buildNavItem(context, 15, 'Dept Comparison', Icons.compare_arrows_outlined, selectedIndex),
                    _buildNavItem(context, 16, 'Notifications & Circulars', Icons.campaign_outlined, selectedIndex),

                    const SizedBox(height: 12),
                    _buildSectionHeader('PLANNING & RESOURCES'),
                    _buildNavItem(context, 17, 'Digital Repository', Icons.folder_open_outlined, selectedIndex),
                    _buildNavItem(context, 18, 'Meetings & BOS', Icons.groups_outlined, selectedIndex),

                    const SizedBox(height: 12),
                    _buildSectionHeader('MY ACCOUNT'),
                    _buildNavItem(context, 19, 'My Profile', Icons.account_circle_outlined, selectedIndex),
                  ],
                ),
              ),

              // IT Support Banner Footer
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.headset_mic_outlined, color: Colors.white70, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Need Help?',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Contact IT Support',
                            style: TextStyle(color: DeanTheme.textSubtle, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String title, IconData icon, int selectedIndex) {
    final isSelected = index == selectedIndex;
    final appState = DeanAppStateProvider.of(context);

    return InkWell(
      onTap: () {
        appState.setNavIndex(index);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? DeanTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DeanTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
