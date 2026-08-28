import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router/route_names.dart';
import '../widgets/app_scaffold.dart' as actual_admin_scaffold;

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return actual_admin_scaffold.AppScaffold(
      currentLocation: currentLocation,
      child: child,
    );
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'admin-root',
);
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'admin-shell',
);

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.dashboard,
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) =>
          AppScaffold(currentLocation: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    ),
  ],
);
