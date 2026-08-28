import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/theme/app_theme.dart';
import 'package:principal_portal/core/widgets/charts/chart_semantics.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';

import 'fixtures/portal_fixtures.dart';

/// Accessibility checks that can actually be run here.
///
/// **Scope, stated honestly.** This is not a WCAG conformance audit. A
/// conformance claim needs axe or Lighthouse against the built page in a real
/// browser, plus a screen reader, and none of that is available from a headless
/// Dart VM. What *is* available is Flutter's own semantics tree and the
/// guideline matchers `flutter_test` ships, which catch the defects that were
/// actually found: unlabelled controls, charts that announce nothing, and
/// tap targets too small to hit.
///
/// Treat a pass here as "the defects we could find and fix are fixed and stay
/// fixed", not as "the portal is accessible".
void main() {
  const surface = Size(1600, 1400);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(surface);
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
    await settle(tester);
  }

  Future<void> open(WidgetTester tester, String label) async {
    await tester.tap(
      find
          .descendant(of: find.byType(SidebarItem), matching: find.text(label))
          .first,
    );
    await settle(tester);
  }

  // ---------------------------------------------------------------------------
  // Charts
  // ---------------------------------------------------------------------------

  group('charts describe themselves', () {
    test('a single series is read out value by value', () {
      final label = ChartSemantics.describe('Bar chart', [
        (label: 'CSE', value: 92.4),
        (label: 'ECE', value: 88.0),
      ]);

      expect(label, contains('CSE 92.4'));
      // A whole number is not read as "eighty eight point zero".
      expect(label, contains('ECE 88'));
      expect(label, isNot(contains('88.0')));
      expect(label, contains('2 values'));
    });

    test('an empty chart says so rather than staying silent', () {
      expect(
        ChartSemantics.describe('Bar chart', const []),
        'Bar chart. No data.',
      );
    });

    test('a long series gives the range instead of sixty numbers', () {
      // A screen reader cannot skim. Reading every point of a long trend is
      // worse than useless — it buries the shape of it.
      final points = [
        for (var i = 0; i < 40; i++) (label: 'W$i', value: i.toDouble()),
      ];
      final label = ChartSemantics.describe('Line chart', points);

      expect(label, contains('40 values'));
      expect(label, contains('from 0'));
      expect(label, contains('to 39'));
      expect(label, isNot(contains('W17')));
    });

    test('a multi-series chart names each series and its range', () {
      final label = ChartSemantics.describeSeries(
        'Line chart',
        const ['2021', '2022', '2023'],
        const [
          (label: 'Admissions', values: [100.0, 140.0, 120.0]),
        ],
      );

      expect(label, contains('2021 to 2023'));
      expect(label, contains('Admissions'));
      expect(label, contains('lowest 100'));
      expect(label, contains('highest 140'));
    });

    testWidgets('every chart on a real screen carries a label', (tester) async {
      await pumpApp(tester);
      await open(tester, 'Institution Overview');

      final handle = tester.ensureSemantics();
      await tester.pump();

      // fl_chart paints to a canvas, so without an explicit label a chart is
      // one unlabelled rectangle — and charts are where most of the meaning on
      // an analytics screen lives. Matched loosely on purpose: the wording
      // differs per chart type and the assertion is that *something* describes
      // itself, not that it uses one exact phrase.
      expect(
        find.bySemanticsLabel(RegExp(r'chart\.')),
        findsWidgets,
        reason: 'No chart announced itself on Institution Overview.',
      );

      // And the description carries figures, not just a chart type.
      expect(find.bySemanticsLabel(RegExp(r'chart\..*\d')), findsWidgets);

      handle.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  group('controls have names and are big enough to hit', () {
    testWidgets('the Dashboard meets the tap-target and label guidelines', (
      tester,
    ) async {
      await pumpApp(tester);

      final handle = tester.ensureSemantics();

      // Flutter's own guideline matchers. These are the checks a manual pass
      // is worst at: a 40px button among a hundred correct ones is invisible
      // in review and obvious to someone using a touch screen.
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    // Tested in isolation rather than inside the running shell. Within the app
    // the rail is a virtualised ListView nested several semantics containers
    // deep, and `getSemantics` there resolves an ancestor rather than the row —
    // which tells you nothing about the row. One row on its own is unambiguous.
    Future<void> pumpItem(
      WidgetTester tester, {
      required bool expanded,
      int badgeCount = 0,
      bool selected = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarItem(
              icon: Icons.dashboard,
              label: 'Institution Overview',
              selected: selected,
              expanded: expanded,
              badgeCount: badgeCount,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an expanded destination announces its name', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpItem(tester, expanded: true);

      final node = tester.getSemantics(find.byType(SidebarItem));

      expect(
        node.label,
        contains('Institution Overview'),
        reason:
            'The rail relied on its Tooltip for a name, and that message is '
            'empty whenever the rail is expanded — which is the normal case, '
            'so every visible destination was unnamed.',
      );
      expect(
        node.flagsCollection.isButton,
        isTrue,
        reason:
            'A destination that does not announce it can be activated '
            'reads as static text.',
      );

      handle.dispose();
    });

    testWidgets('a collapsed destination still announces its name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpItem(tester, expanded: false);

      expect(
        tester.getSemantics(find.byType(SidebarItem)).label,
        contains('Institution Overview'),
      );

      handle.dispose();
    });

    testWidgets('a pending count is attached to the destination it belongs to', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpItem(tester, expanded: true, badgeCount: 3);

      // Previously the badge was a bare "3" with nothing to attach it to.
      // Matched with `contains`: merging joins the parts with a newline, and
      // the exact whitespace is Flutter's business rather than the assertion's.
      expect(
        tester.getSemantics(find.byType(SidebarItem)).label,
        contains('Institution Overview, 3 pending'),
      );

      handle.dispose();
    });

    testWidgets('the current page announces that it is selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpItem(tester, expanded: true, selected: true);

      expect(
        tester
            .getSemantics(find.byType(SidebarItem))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
        reason:
            'The active destination is marked only by a colour and a rule, '
            'neither of which a screen reader can convey.',
      );

      handle.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Focus
  // ---------------------------------------------------------------------------

  group('keyboard focus', () {
    test('focus is styled more strongly than hover', () {
      // The portal turns off splash and highlight for pointer use, which left
      // keyboard focus on Material's default black12 wash — the same weight as
      // the hover tint, so tabbing looked like hovering.
      final theme = AppTheme.light;

      expect(theme.focusColor.a, greaterThan(theme.hoverColor.a));
    });

    testWidgets('tab moves focus into the page and something takes it', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.primaryFocus,
        isNotNull,
        reason:
            'Nothing accepted keyboard focus, so the portal cannot be '
            'operated without a mouse.',
      );
    });
  });
}
