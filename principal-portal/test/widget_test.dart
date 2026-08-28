import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/constants/nav_destinations.dart';
import 'package:principal_portal/core/router/app_routes.dart';
import 'package:principal_portal/core/widgets/layout/sidebar.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';
import 'fixtures/portal_fixtures.dart';

/// The portal is desktop-first with a 1024px floor; the default 800x600
/// test surface sits below that and overflows by design. Render at a real
/// desktop viewport instead.
const Size _desktopSurface = Size(1440, 900);

/// Widths every page must render at without overflowing: wide desktop,
/// the common laptop sizes, the documented floor, and a tablet below it.
///
/// Heights are deliberately generous. These cases exist to catch
/// horizontal overflow, and a tall surface keeps every sidebar row built
/// so navigation does not depend on scrolling the rail first.
const List<double> _widths = [1600, 1440, 1280, 1024, 900];
const double _tallSurface = 1500;

/// Longer than mock_delay.dart's 400ms, so provider futures resolve.
/// pumpAndSettle alone will not advance them: a pending Riverpod future
/// schedules no frames, so settling returns with the timer still armed.
const Duration _mockLatency = Duration(milliseconds: 600);

/// Settles the tree AND the mock latency behind it.
///
/// pumpAndSettle alone is not enough: a pending Riverpod future schedules
/// no frames, so settling returns with the timer still armed. Navigating
/// mounts a fresh branch whose providers start their own timers during
/// that frame, so a single pump-then-settle leaves the new page showing
/// only its header. Repeating drains each generation of timers.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(_mockLatency);
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = _desktopSurface,
}) async {
  // flutter_test defaults devicePixelRatio to 3.0, which would render a
  // 1600px surface as 533 logical pixels and quietly test the wrong
  // breakpoints. Pin it to 1 so these sizes mean what they say.
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() {
    tester.view.reset();
    return tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    ProviderScope(overrides: portalOverrides(), child: const PrincipalPortalApp()),
  );
  await _settle(tester);
}

/// Taps a sidebar row, scrolling the rail first when the destination sits
/// below the fold — the list is long enough that off-screen rows are not
/// built yet. Below the desktop floor the rail is icon-only, so the label
/// exists as a tooltip rather than as visible text.
Future<void> _openDestination(WidgetTester tester, NavDestination dest) async {
  Finder target = find.descendant(
    of: find.byType(SidebarItem),
    matching: find.text(dest.label),
  );
  if (target.evaluate().isEmpty) {
    target = find.byTooltip(dest.label);
  }

  if (target.evaluate().isEmpty) {
    final sidebarList = find.descendant(
      of: find.byType(Sidebar),
      matching: find.byType(ListView),
    );
    if (sidebarList.evaluate().isNotEmpty) {
      for (int i = 0; i < 5; i++) {
        await tester.drag(sidebarList.first, const Offset(0, -200));
        await tester.pumpAndSettle();
        target = find.descendant(
          of: find.byType(SidebarItem),
          matching: find.text(dest.label),
        );
        if (target.evaluate().isEmpty) {
          target = find.byTooltip(dest.label);
        }
        if (target.evaluate().isNotEmpty) break;
      }
    }
  }

  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first);
    await _settle(tester);
  }
}

void main() {
  testWidgets('App shell renders the Dashboard destination by default', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Dashboard'), findsWidgets);
  });

  for (final width in _widths) {
    testWidgets('Destinations render without overflow at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpApp(tester, size: Size(width, _tallSurface));

      for (final destination in kNavDestinations) {
        await _openDestination(tester, destination);
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${destination.label} threw or overflowed at '
              '${width.toInt()}px',
        );
      }
    });
  }

  testWidgets('Every tab of every tabbed page renders without error', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1440, _tallSurface));

    for (final destination in kNavDestinations) {
      await _openDestination(tester, destination);

      // TabBarView only builds the visible tab, so each one has to be
      // selected to be exercised at all.
      final tabCount = find.byType(Tab).evaluate().length;
      for (int i = 0; i < tabCount; i++) {
        final tabFinder = find.byType(Tab).at(i);
        await tester.ensureVisible(tabFinder);
        await tester.pumpAndSettle();
        await tester.tap(tabFinder);
        await _settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '${destination.label} tab $i threw while rendering',
        );
      }
    }
  });

  test('Navigation indices resolve for every destination', () {
    for (final destination in kNavDestinations) {
      expect(
        navIndexOf(destination.path),
        isNonNegative,
        reason: '${destination.path} is missing from kNavDestinations',
      );
    }
    expect(navIndexOf(AppRoutes.myProfile), isNonNegative);
    expect(navIndexOf(AppRoutes.notifications), isNonNegative);
  });
}
