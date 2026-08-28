import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../theme/app_icons.dart';

/// One sidebar destination: icon, label, and the route path it maps to.
/// Order here defines both sidebar order and the router's shell branch
/// order (index-matched).
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.label,
    required this.path,
    this.showsPendingBadge = false,
  });

  final IconData icon;
  final String label;
  final String path;

  /// Whether this row renders a live count badge (pending approvals,
  /// unread notifications). The count itself comes from the feature
  /// provider, not from this constant list.
  final bool showsPendingBadge;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(
    icon: AppIcons.dashboard,
    label: 'Dashboard',
    path: AppRoutes.dashboard,
  ),
  NavDestination(
    icon: AppIcons.institution,
    label: 'Institution Overview',
    path: AppRoutes.institutionOverview,
  ),
  NavDestination(
    icon: AppIcons.academic,
    label: 'Academic Performance',
    path: AppRoutes.academicPerformance,
  ),
  NavDestination(
    icon: AppIcons.results,
    label: 'Result',
    path: AppRoutes.resultAnalytics,
  ),
  NavDestination(
    icon: AppIcons.department,
    label: 'Department Performance',
    path: AppRoutes.departmentPerformance,
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
    icon: AppIcons.examinations,
    label: 'Examination Monitoring',
    path: AppRoutes.examinationMonitoring,
  ),
  NavDestination(
    icon: AppIcons.innovation,
    label: 'Research & Innovation',
    path: AppRoutes.researchInnovation,
  ),

  NavDestination(
    icon: AppIcons.finance,
    label: 'Scholarships',
    path: AppRoutes.scholarships,
  ),
  NavDestination(
    icon: AppIcons.placements,
    label: 'Placement Dashboard',
    path: AppRoutes.placementDashboard,
  ),
  NavDestination(
    icon: AppIcons.approvals,
    label: 'Approvals',
    path: AppRoutes.approvals,
    showsPendingBadge: true,
  ),
  NavDestination(
    icon: AppIcons.circulars,
    label: 'Circulars & Announcements',
    path: AppRoutes.circulars,
  ),
  NavDestination(
    icon: AppIcons.meetings,
    label: 'Meetings & Calendar',
    path: AppRoutes.meetingsCalendar,
  ),
  NavDestination(
    icon: AppIcons.reports,
    label: 'Reports & Analytics',
    path: AppRoutes.reportsAnalytics,
  ),
  NavDestination(
    icon: AppIcons.audit,
    label: 'Audit & Compliance',
    path: AppRoutes.auditCompliance,
  ),
  NavDestination(
    icon: AppIcons.notifications,
    label: 'Notifications',
    path: AppRoutes.notifications,
    showsPendingBadge: true,
  ),
  NavDestination(
    icon: AppIcons.profile,
    label: 'My Profile',
    path: AppRoutes.myProfile,
  ),
];

/// Branch index of a destination, resolved by path so reordering
/// [kNavDestinations] can never point navigation at the wrong screen.
int navIndexOf(String path) =>
    kNavDestinations.indexWhere((destination) => destination.path == path);
