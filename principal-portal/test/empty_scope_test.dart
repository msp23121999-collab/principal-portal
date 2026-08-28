import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/services/repository.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';
import 'package:principal_portal/features/faculty/data/faculty_detail_repository.dart';
import 'package:principal_portal/features/faculty/data/faculty_repository.dart';
import 'package:principal_portal/features/faculty/models/faculty.dart';
import 'package:principal_portal/features/faculty/models/faculty_detail.dart';
import 'package:principal_portal/features/faculty/providers/faculty_providers.dart';

import 'fixtures/portal_fixtures.dart';

/// Proves the portal survives a scope that matches nothing.
///
/// Ten of the twelve departments have no students today, and several have no
/// staff, so "the filter matched nobody" is an ordinary state rather than an
/// edge case. Three cards on Faculty Performance divided by `roster.length`
/// without checking it, so choosing one of those departments printed the
/// literal text `NaN` on screen — a KPI card reading "NaN hrs".
///
/// `NaN` is the visible symptom of an unguarded `0 / 0`. Asserting it never
/// appears catches the whole family, including any new card that repeats the
/// mistake.
const Size _surface = Size(1600, 1500);
const Duration _mockLatency = Duration(milliseconds: 600);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(_mockLatency);
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() {
    tester.view.reset();
    return tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...portalOverrides(), ...overrides],
      child: const PrincipalPortalApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _open(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(of: find.byType(SidebarItem), matching: find.text(label))
        .first,
  );
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await _settle(tester);
}

/// A roster with nobody in it — what every screen sees when the department
/// filter matches no staff.
class _EmptyFacultyRepository implements FacultyRepository {
  const _EmptyFacultyRepository();

  @override
  Future<Sourced<List<Faculty>>> fetchAll() async =>
      const Sourced<List<Faculty>>(<Faculty>[], DataSource.live);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyFacultyDetails implements FacultyDetailRepository {
  const _EmptyFacultyDetails();

  @override
  Future<Sourced<Map<String, FacultyDetail>>> fetchAll(
    List<Faculty> roster,
  ) async => const Sourced<Map<String, FacultyDetail>>(
    <String, FacultyDetail>{},
    DataSource.live,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('An empty roster never prints NaN', () {
    testWidgets('Faculty Performance renders every tab with nobody on roll', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        overrides: [
          facultyRepositoryProvider.overrideWithValue(
            const _EmptyFacultyRepository(),
          ),
          facultyDetailRepositoryProvider.overrideWithValue(
            const _EmptyFacultyDetails(),
          ),
        ],
      );

      await _open(tester, 'Faculty Performance');

      // Guard against a vacuous pass: if navigation silently failed, "no NaN
      // on screen" would be true because the screen was never there.
      expect(
        find.text('Faculty Performance'),
        findsWidgets,
        reason: 'The screen must actually be open for the assertions below.',
      );

      for (final tab in const [
        'Roster',
        'Workload & Appraisal',
        'Research Output',
      ]) {
        await _openTab(tester, tab);

        expect(
          find.byType(Tab),
          findsWidgets,
          reason: 'The tab strip must have rendered.',
        );
        expect(
          find.textContaining('NaN'),
          findsNothing,
          reason:
              'The "$tab" tab divided by roster.length without checking it. '
              'With no staff in scope that is 0 / 0, and '
              'NaN.toStringAsFixed(1) renders as the text "NaN".',
        );
        expect(
          find.textContaining('Infinity'),
          findsNothing,
          reason: 'The other face of an unguarded division by zero.',
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
