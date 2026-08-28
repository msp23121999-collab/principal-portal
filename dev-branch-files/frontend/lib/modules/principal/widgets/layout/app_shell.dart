import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/principal_compat.dart';
import '../../providers/notifications_providers.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// Persistent app chrome (Sidebar + TopBar) wrapping every route branch.
/// Built once by go_router's StatefulShellRoute — never rebuilt on
/// navigation, so sidebar/topbar state (collapse, search text) survives
/// switching between the 13 destinations. This is the app's composition
/// root, so — unlike other core/widgets — it may reach into a feature
/// provider (unread notification count) to keep the TopBar badge live.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Sidebar(
            selectedIndex: navigationShell.currentIndex,
            onSelect: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            onLogout: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout simulated (no auth backend yet).'),
                ),
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  unreadNotificationCount: unreadCount,
                  onNotificationsTap: () {
                    final notificationsIndex = kNotificationsBranchIndex;
                    navigationShell.goBranch(notificationsIndex);
                  },
                  onProfileTap: () {
                    navigationShell.goBranch(kProfileBranchIndex);
                  },
                ),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Index-matched to [kNavDestinations] order in nav_destinations.dart.
const int kProfileBranchIndex = 1;
const int kNotificationsBranchIndex = 11;
