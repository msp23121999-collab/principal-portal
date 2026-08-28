import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/filters/portal_filter_providers.dart';
import 'package:principal_portal/core/services/repository.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';
import 'package:principal_portal/features/institution/data/department_repository.dart';
import 'package:principal_portal/features/institution/models/department.dart';
import 'package:principal_portal/features/institution/providers/institution_providers.dart';

import 'fixtures/portal_fixtures.dart';

/// A database with no departments seeded yet.
class _NoDepartments implements DepartmentRepository {
  const _NoDepartments();

  @override
  Future<Sourced<List<Department>>> fetchAll() async =>
      const Sourced<List<Department>>(<Department>[], DataSource.live);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The Principal Dashboard's filters must change the dashboard.
///
/// Decorative dropdowns are worse than none: they invite the Principal to
/// narrow the scope and then quietly answer a different question. Department
/// Performance and the Result chart both used to read institution-wide data
/// regardless of the filter row directly above them, so choosing CSE left
/// twelve departments on screen under a control claiming otherwise.
///
/// Attendance Snapshot is asserted absent here too. Attendance is already
/// reported by the KPI card, Student Summary and Faculty Status; a fourth view
/// of it made the page longer without answering a new question.
const Size _surface = Size(1600, 2400);
const Duration _mockLatency = Duration(milliseconds: 600);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(_mockLatency);
    await tester.pumpAndSettle();
  }
}

Future<ProviderContainer> _pumpDashboard(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() {
    tester.view.reset();
    return tester.binding.setSurfaceSize(null);
  });

  // Fixtures first so a test-specific override still wins.
  final container = ProviderContainer(
    overrides: [...portalOverrides(), ...overrides],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PrincipalPortalApp(),
    ),
  );
  await _settle(tester);
  return container;
}

void main() {
  group('Principal Dashboard filters', () {
    testWidgets('choosing a department narrows Department Performance', (
      tester,
    ) async {
      final container = await _pumpDashboard(tester);

      // Both fixture departments are listed before any filter is applied.
      expect(find.textContaining('IOT'), findsWidgets);
      expect(find.textContaining('CSE'), findsWidgets);

      container.read(portalFiltersProvider.notifier).setDepartment('CSE');
      await _settle(tester);

      expect(
        find.textContaining('IOT ·'),
        findsNothing,
        reason:
            'IOT should have dropped out of Department Performance when the '
            'department filter was set to CSE.',
      );
      expect(find.textContaining('CSE ·'), findsWidgets);
    });

    testWidgets('no departments on record gets a message, not a blank card', (
      tester,
    ) async {
      // A fresh database, before any department is seeded. The panel must say
      // so: a blank card reads as a failure to load rather than as nothing to
      // show.
      await _pumpDashboard(
        tester,
        overrides: [
          departmentRepositoryProvider.overrideWithValue(
            const _NoDepartments(),
          ),
        ],
      );

      expect(
        find.textContaining('No department data for the selected filters'),
        findsOneWidget,
      );
    });

    testWidgets('switching department does not crash on a stale batch', (
      tester,
    ) async {
      final container = await _pumpDashboard(tester);
      final notifier = container.read(portalFiltersProvider.notifier);

      // The sequence that used to take the page down. Batches are offered per
      // department, so a batch chosen in CSE need not exist in IOT — and
      // DropdownButton asserts when its value is not among its items.
      notifier.setDepartment('CSE');
      await _settle(tester);

      final csebatches = container.read(filterBatchesProvider);
      if (csebatches.isNotEmpty) {
        notifier.setBatch(csebatches.first);
        await _settle(tester);
      }

      notifier.setDepartment('IOT');
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        container.read(portalFiltersProvider).batch,
        isNull,
        reason:
            'The batch belonged to the department that was just replaced, so '
            'it must be cleared rather than carried across.',
      );
    });

    testWidgets('each dropdown offers only what survives the ones above it', (
      tester,
    ) async {
      final container = await _pumpDashboard(tester);
      final notifier = container.read(portalFiltersProvider.notifier);

      final allBatches = container.read(filterBatchesProvider).toSet();
      notifier.setDepartment('CSE');
      await _settle(tester);
      final cseBatches = container.read(filterBatchesProvider).toSet();

      expect(
        allBatches.containsAll(cseBatches),
        isTrue,
        reason:
            'Narrowing to one department cannot introduce a batch the '
            'institution does not have.',
      );
    });

    testWidgets('resetting filters restores the institution-wide view', (
      tester,
    ) async {
      final container = await _pumpDashboard(tester);
      final notifier = container.read(portalFiltersProvider.notifier);

      notifier.setDepartment('CSE');
      await _settle(tester);
      expect(find.textContaining('IOT ·'), findsNothing);

      notifier.clearAll();
      await _settle(tester);

      expect(container.read(portalFiltersProvider).activeCount, 0);
      expect(find.textContaining('IOT ·'), findsWidgets);
    });
  });

  group('Principal Dashboard composition', () {
    testWidgets('Attendance Snapshot is not on the dashboard', (tester) async {
      await _pumpDashboard(tester);

      expect(
        find.text('Attendance Snapshot'),
        findsNothing,
        reason:
            'Removed as duplicated information — attendance is already on the '
            'KPI card, Student Summary and Faculty Status. The detailed trend '
            'lives on Attendance Analytics.',
      );
    });

    testWidgets('the dashboard shows no Average CGPA', (tester) async {
      await _pumpDashboard(tester);
      expect(find.textContaining('Average CGPA'), findsNothing);
    });

    testWidgets('Faculty Status does not restate Total Faculty', (
      tester,
    ) async {
      await _pumpDashboard(tester);

      // The panel counts the attendance register, which covers fewer people
      // than the roster. Calling that "Total Faculty" put two different
      // answers to one question on the same screen.
      expect(find.text('On Register'), findsOneWidget);
      expect(
        find.text('Total Faculty'),
        findsOneWidget,
        reason: 'Only the KPI card should carry this label.',
      );
    });

    testWidgets('Attendance Analytics still has its trend', (tester) async {
      await _pumpDashboard(tester);

      await tester.tap(
        find
            .descendant(
              of: find.byType(SidebarItem),
              matching: find.text('Attendance Analytics'),
            )
            .first,
      );
      await _settle(tester);

      expect(
        find.text('Attendance Trend'),
        findsOneWidget,
        reason:
            'Removing the dashboard snapshot must not touch the dedicated '
            'attendance screen.',
      );
    });
  });
}
