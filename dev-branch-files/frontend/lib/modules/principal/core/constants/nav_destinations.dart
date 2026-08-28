import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../principal_compat.dart';

/// One sidebar destination: icon, label, and the route path it maps to.
/// Order here defines both sidebar order and the router's shell branch
/// order (index-matched).
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(
    icon: AppIcons.dashboard,
    label: 'Dashboard',
    path: AppRoutes.dashboard,
  ),
  NavDestination(
    icon: AppIcons.profile,
    label: 'Profile',
    path: AppRoutes.profile,
  ),
  NavDestination(
    icon: AppIcons.institution,
    label: 'Institution Analytics',
    path: AppRoutes.institutionAnalytics,
  ),
  NavDestination(
    icon: AppIcons.department,
    label: 'Department Analytics',
    path: AppRoutes.departmentAnalytics,
  ),
  NavDestination(
    icon: AppIcons.faculty,
    label: 'Faculty Performance',
    path: AppRoutes.facultyPerformance,
  ),
  NavDestination(
    icon: AppIcons.students,
    label: 'Student Performance',
    path: AppRoutes.studentPerformance,
  ),
  NavDestination(
    icon: AppIcons.attendance,
    label: 'Attendance Analytics',
    path: AppRoutes.attendanceAnalytics,
  ),
  NavDestination(
    icon: AppIcons.results,
    label: 'Result Analytics',
    path: AppRoutes.resultAnalytics,
  ),
  NavDestination(
    icon: AppIcons.placements,
    label: 'Placement Analytics',
    path: AppRoutes.placementAnalytics,
  ),
  NavDestination(
    icon: AppIcons.leave,
    label: 'Leave Approval',
    path: AppRoutes.leaveApproval,
  ),
  NavDestination(
    icon: AppIcons.reports,
    label: 'Reports',
    path: AppRoutes.reports,
  ),
  NavDestination(
    icon: AppIcons.notifications,
    label: 'Notifications',
    path: AppRoutes.notifications,
  ),
  NavDestination(
    icon: AppIcons.settings,
    label: 'Settings',
    path: AppRoutes.settings,
  ),
];
