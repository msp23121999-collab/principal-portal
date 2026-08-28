import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/approvals/providers/approvals_providers.dart';
import '../../../features/notifications/providers/notifications_providers.dart';
import '../../../features/profile/providers/principal_profile_providers.dart';
import '../../constants/nav_destinations.dart';
import '../../router/app_routes.dart';
import '../../services/refresh_on_focus.dart';
import '../../theme/app_colors.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// Persistent app chrome (Sidebar + TopBar) wrapping every route branch.
/// Built once by go_router's StatefulShellRoute — never rebuilt on
/// navigation, so sidebar/topbar state (collapse, search text) survives
/// switching destinations. This is the app's composition root, so — unlike
/// other core/widgets — it may reach into feature providers to keep the
/// TopBar badge and the sidebar pending counts live.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final pendingApprovals = ref.watch(totalPendingApprovalsProvider);
    // Null while the profile loads, or when it cannot be read at all — the
    // chrome must not block on it, and must not invent a name to fill the gap.
    //
    // The blank case is checked as well as the null one. `??` only fires on
    // null, and `PrincipalProfile.name` is built with `row.strOr('name', '')`,
    // so a NULL or blank `name` column produced an empty string that flowed
    // through to `profileName.characters.first` below and threw
    // `Bad state: No element` — taking the whole shell down on every route,
    // not just the profile screen. `PrincipalIdentity.displayName()` already
    // guards the same value the same way.
    final String? resolvedName = ref
        .watch(principalProfileProvider)
        .valueOrNull
        ?.name
        .trim();
    final String profileName = (resolvedName == null || resolvedName.isEmpty)
        ? 'Principal'
        : resolvedName;

    // Mounted here rather than on the Dashboard because the shell outlives
    // every branch: a Principal who leaves the portal on Approvals and comes
    // back an hour later needs the same refresh as one who left it on the
    // Dashboard.
    return RefreshOnFocus(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            Sidebar(
              selectedIndex: navigationShell.currentIndex,
              badgeCounts: {
                AppRoutes.notifications: unreadCount,
                AppRoutes.approvals: pendingApprovals,
              },
              onSelect: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  TopBar(
                    unreadNotificationCount: unreadCount,
                    // The signed-in Principal, not a name compiled into the app.
                    // Until the profile resolves the TopBar keeps its own
                    // neutral default rather than showing someone else's name.
                    userName: profileName,
                    userInitial: profileName.characters.first,
                    onNotificationsTap: () => navigationShell.goBranch(
                      navIndexOf(AppRoutes.notifications),
                    ),
                    onProfileTap: () => navigationShell.goBranch(
                      navIndexOf(AppRoutes.myProfile),
                    ),
                    // Search results jump to the branch that owns them; the
                    // shell is the only place that knows how to switch branch.
                    onSearchNavigate: (route) =>
                        navigationShell.goBranch(navIndexOf(route)),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
