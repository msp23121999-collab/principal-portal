import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/widgets/feedback/empty_state.dart';
import 'package:principal_portal/core/widgets/feedback/error_state.dart';
import 'package:principal_portal/core/widgets/feedback/loading_skeleton.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';
import 'package:principal_portal/features/institution/providers/institution_providers.dart';

import 'fixtures/portal_fixtures.dart';

/// Behavioural QA: proves the things a user actually experiences, as
/// opposed to the code-health checks the audit covered.
///
/// The three async branches — loading, error, empty — are the point. Every
/// screen declares all three, but nothing had ever rendered them, so until
/// now "the app handles failure" was an assertion rather than a fact.
const Size _surface = Size(1600, 1500);
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

Future<void> _sizeSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() {
    tester.view.reset();
    return tester.binding.setSurfaceSize(null);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await _sizeSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      // Fixtures first so a test-specific override still wins.
      overrides: [...portalOverrides(), ...overrides],
      child: const PrincipalPortalApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _open(WidgetTester tester, String label) async {
  final target = find.descendant(of: find.byType(SidebarItem), matching: find.text(label)).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  // The TabBar scrolls, so a later tab can sit off the visible strip and be
  // unhittable where it lands. Bringing it into view first is what a user
  // does, and keeps the tap from silently missing.
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await _settle(tester);
}

void main() {
  group('Async states actually render', () {
    testWidgets('Loading skeletons show while data is still resolving', (
      tester,
    ) async {
      await _sizeSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: portalOverrides(),
          child: const PrincipalPortalApp(),
        ),
      );

      // One frame in, the 400ms mock latency has not elapsed, so every
      // section should be showing its placeholder rather than real data.
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsWidgets);

      // Once the latency passes, the skeletons are replaced by content.
      await _settle(tester);
      expect(find.byType(LoadingSkeleton), findsNothing);
    });

    testWidgets('A failing provider renders the error state, not a crash', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        overrides: [
          // The KPI cards no longer surface this: they are counted from the
          // department rollup, and the stored snapshots supply only the NIRF
          // ranking, which degrades to an em dash rather than an error. Failing
          // the semester performance series instead exercises the same thing —
          // one section down, the rest of the page up.
          semesterPerformanceProvider.overrideWith(
            (ref) => Future.error(Exception('simulated backend failure')),
          ),
        ],
      );
      await _open(tester, 'Institution Overview');

      expect(find.byType(ErrorState), findsWidgets);
      // The rest of the page keeps working — one failed section does not
      // take the screen down with it.
      expect(find.text('Institution Overview'), findsWidgets);
      expect(find.text('Department Summary'), findsWidgets);
    });

    testWidgets('An empty result set renders the empty state', (tester) async {
      await _pumpApp(tester);
      // Subject analysis moved off Academic Performance and onto Result when
      // the two duplicate views were merged into one.
      await _open(tester, 'Result');
      await _openTab(tester, 'Subject-wise');

      // A real result set first.
      expect(find.byType(EmptyState), findsNothing);

      // Scrolled into view first: the search box sits below the KPI row and
      // the charts, so on a shorter surface it is not built until reached.
      final search = find.widgetWithText(
        TextField,
        'Search subject, code, or faculty',
      );
      // Scrolled to rather than ensureVisible: the tab body is lazy, so on a
      // shorter surface the field is not built at all until it is reached.
      await tester.scrollUntilVisible(
        search,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      await tester.enterText(search, 'zzzzz-no-such-subject');
      await _settle(tester);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.text('No subjects match the current search.'),
        findsOneWidget,
      );
    });
  });

  group('Filters and search do real work', () {
    testWidgets('Applying a department filter narrows the summary table', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _open(tester, 'Institution Overview');

      // Unfiltered, the table paginates 12 departments five at a time.
      expect(find.textContaining('of 12 departments'), findsOneWidget);

      // The shared filter applies on selection — the page's own Apply and
      // Reset went when its second filter row was folded into the portal-wide
      // one. Departments are listed by code there, not by full name.
      await tester.tap(find.text('All Departments').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CIVIL').last);
      await _settle(tester);

      expect(find.textContaining('of 1 departments'), findsOneWidget);
    });

    testWidgets('Changing rows per page changes how much of the table shows', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _open(tester, 'Institution Overview');

      expect(find.textContaining('Showing 1 to 5 of 12'), findsOneWidget);

      // The pagination bar sits well below the fold on this page, so it
      // has to be scrolled into view before it can be tapped.
      await tester.ensureVisible(find.text('5 / page').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 / page').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('25 / page').last);
      await _settle(tester);

      expect(find.textContaining('Showing 1 to 12 of 12'), findsOneWidget);
    });

    testWidgets('A category chip filters the notice board', (tester) async {
      await _pumpApp(tester);
      await _open(tester, 'Circulars & Announcements');

      expect(find.textContaining('KSRCE/PRIN/'), findsWidgets);
      final unfiltered = find.textContaining('KSRCE/PRIN/').evaluate().length;

      // FilterChipGroup renders its own InkWell-based chips rather than
      // Material's FilterChip, so target the label directly.
      await tester.tap(find.text('Examination').first);
      await _settle(tester);

      final filtered = find.textContaining('KSRCE/PRIN/').evaluate().length;
      expect(filtered, lessThan(unfiltered));
      expect(filtered, greaterThan(0));
    });
  });

  group('Chrome behaves', () {
    testWidgets('Collapsing the sidebar hides labels but keeps navigation', (
      tester,
    ) async {
      await _pumpApp(tester);

      final itemFinder = find.descendant(
        of: find.byType(SidebarItem),
        matching: find.text('Approvals'),
      );
      expect(itemFinder, findsOneWidget);

      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();

      // Label gone, but the row is still there and still reachable.
      expect(
        find.descendant(
          of: find.byType(SidebarItem),
          matching: find.text('Approvals'),
        ),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Approvals'));
      await _settle(tester);
      expect(find.text('Approvals'), findsWidgets);
    });

    testWidgets('Tab selection survives navigating away and back', (
      tester,
    ) async {
      await _pumpApp(tester);
      // Finance Overview was removed and Scholarships has no tabs, so this
      // now proves the same thing on Result, which still does.
      await _open(tester, 'Result');
      await _openTab(tester, 'Subject-wise');
      expect(find.text('Subject Performance'), findsOneWidget);

      await _open(tester, 'Dashboard');
      await _open(tester, 'Result');

      // Each branch keeps its own Navigator, so the tab is still selected.
      expect(find.text('Subject Performance'), findsOneWidget);
    });
  });
}
