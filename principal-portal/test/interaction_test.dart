import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/widgets/buttons/icon_action_button.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';

import 'fixtures/portal_fixtures.dart';

/// Tall enough that every sidebar row stays built, so navigation does not
/// depend on scrolling the rail first.
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

Future<void> _pumpApp(WidgetTester tester) async {
  // flutter_test defaults devicePixelRatio to 3.0; pin it to 1 so the
  // surface size above is the logical width the layout actually sees.
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() {
    tester.view.reset();
    return tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: portalOverrides(),
      child: const PrincipalPortalApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _openDestination(WidgetTester tester, String label) async {
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
  testWidgets('Approving an event request records the decision and remark', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDestination(tester, 'Approvals');
    await _openTab(tester, 'Event & Activity');

    // Was a budget request. `approvalRequestsProvider` now keeps only academic
    // and event categories — budget and purchase belong to Admin/Finance — so
    // a budget request is not something this screen can ever show.
    expect(find.text('National Technical Symposium'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').first);
    await _settle(tester);

    // The dialog shows the full request before any decision is committed.
    expect(find.text('Approve Request'), findsOneWidget);
    expect(find.text('National Technical Symposium'), findsWidgets);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Cleared against reserves.',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Approval'));
    await _settle(tester);

    expect(find.text('Approve Request'), findsNothing);
    expect(find.text('Cleared against reserves.'), findsOneWidget);
  });

  testWidgets('Cancelling a rejection leaves the request pending', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDestination(tester, 'Approvals');
    await _openTab(tester, 'Academic');

    final rejectButtons = find.widgetWithText(OutlinedButton, 'Reject');
    final pendingBefore = rejectButtons.evaluate().length;
    expect(pendingBefore, greaterThan(0));

    await tester.tap(rejectButtons.first);
    await _settle(tester);
    expect(find.text('Reject Request'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await _settle(tester);

    expect(find.text('Reject Request'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'Reject').evaluate().length,
      pendingBefore,
    );
  });

  testWidgets('A composed notice is saved to drafts and can be published', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDestination(tester, 'Circulars & Announcements');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Notice'));
    await _settle(tester);

    // Scoped to the dialog: the top bar's search box is also a TextField
    // and sits earlier in the tree.
    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(dialogFields, findsNWidgets(2));

    await tester.enterText(
      dialogFields.first,
      'Library timings during examinations',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save as Draft'));
    await _settle(tester);

    await _openTab(tester, 'Drafts');
    expect(find.text('Library timings during examinations'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Publish').first);
    await _settle(tester);

    // Gone from Drafts, now on the Published board.
    expect(find.text('Library timings during examinations'), findsNothing);
    await _openTab(tester, 'Published');
    expect(find.text('Library timings during examinations'), findsOneWidget);
  });

  testWidgets('A scheduled meeting appears in the upcoming list', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDestination(tester, 'Meetings & Calendar');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Schedule Meeting'));
    await _settle(tester);

    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.first, 'Hostel maintenance review');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Schedule'));
    await _settle(tester);

    await _openTab(tester, 'Meetings');
    expect(find.text('Hostel maintenance review'), findsOneWidget);
  });

  testWidgets('The faculty drill-down opens a profile with workload detail', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openDestination(tester, 'Faculty Performance');
    await _openTab(tester, 'Workload & Appraisal');

    // Target the first drill-down button rather than a named row: the
    // table sorts by workload and scrolls, so any given person may sit
    // below the fold.
    final drillDown = find.byWidgetPredicate(
      (widget) =>
          widget is IconActionButton && widget.tooltip.startsWith('View '),
    );
    expect(drillDown, findsWidgets);

    await tester.tap(drillDown.first);
    await _settle(tester);

    expect(find.text('Teaching Workload'), findsOneWidget);
    expect(find.text('Appraisal & Feedback'), findsOneWidget);
    expect(find.text('Weekly contact hours'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Close'));
    await _settle(tester);
    expect(find.text('Teaching Workload'), findsNothing);
  });

  testWidgets('A generated report lands in the report history', (tester) async {
    await _pumpApp(tester);
    await _openDestination(tester, 'Reports & Analytics');
    await _openTab(tester, 'Generate');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Report'));
    await _settle(tester);

    await _openTab(tester, 'Recently Generated');
    // The configurator defaults to Academic Performance, current semester.
    expect(
      find.text('Academic Performance — Current Semester'),
      findsOneWidget,
    );

    // No status chip: the file is written the moment Generate is pressed, so
    // there is no queue for a report to sit in. The tab used to show 'Queued'
    // against a background job that did not exist.
    expect(find.text('Queued'), findsNothing);
    expect(find.text('Report History'), findsOneWidget);
  });

  testWidgets('Sidebar approval badge drops when a request is decided', (
    tester,
  ) async {
    await _pumpApp(tester);

    int badgeCount() {
      final item = tester.widgetList<SidebarItem>(find.byType(SidebarItem));
      return item.firstWhere((i) => i.label == 'Approvals').badgeCount;
    }

    final before = badgeCount();
    expect(before, greaterThan(0));

    await _openDestination(tester, 'Approvals');
    await _openTab(tester, 'Event & Activity');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').first);
    await _settle(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Approval'));
    await _settle(tester);

    expect(badgeCount(), before - 1);
  });

  testWidgets(
    'Department Summary row action button navigates to Department Performance with selected department',
    (tester) async {
      await _pumpApp(tester);
      await _openDestination(tester, 'Institution Overview');

      final actionButtons = find.byWidgetPredicate(
        (widget) =>
            widget is IconActionButton && widget.tooltip.startsWith('View '),
      );
      expect(actionButtons, findsWidgets);

      await tester.tap(actionButtons.first);
      await _settle(tester);

      expect(find.text('Department Performance'), findsWidgets);
    },
  );
}
