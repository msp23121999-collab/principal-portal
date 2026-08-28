import 'package:flutter/material.dart';
import 'common_home_screen.dart';
import 'package:erp_unified/modules/faculty/screens/dashboard_screen.dart' as cams;

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, this.role = 'student'});

  final String role;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  void _logoutToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CommonHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return cams.DashboardScreen(showSidebar: true, onLogout: _logoutToHome);
  }
}
