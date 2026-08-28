import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/services/repository.dart';
import 'package:principal_portal/features/approvals/data/approvals_repository.dart';
import 'package:principal_portal/features/approvals/models/approval_request.dart';
import 'package:principal_portal/features/approvals/providers/approvals_providers.dart';
import 'package:principal_portal/features/approvals/providers/approvals_refresh_provider.dart';
import 'package:principal_portal/features/approvals/widgets/approvals_refresh_button.dart';
import 'package:principal_portal/features/leave/data/leave_repository.dart';
import 'package:principal_portal/features/leave/models/leave_request.dart';
import 'package:principal_portal/features/leave/providers/leave_providers.dart';

/// Covers the Approvals refresh.
///
/// The point of a refresh button is that it goes back to the database, so these
/// count the fetches the repositories actually receive rather than asserting on
/// the spinner. A control that merely re-rendered cached state would satisfy
/// every visual assertion and none of these.
const _latency = Duration(milliseconds: 50);

/// Counts fetches and can be told what to return next, so a test can change the
/// "database" between refreshes and check the UI followed.
class _CountingApprovals implements ApprovalsRepository {
  int fetchCount = 0;
  List<ApprovalRequest> rows = _seed;

  @override
  Future<Sourced<List<ApprovalRequest>>> fetchAll() async {
    fetchCount++;
    await Future<void>.delayed(_latency);
    return Sourced(rows, DataSource.live);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingLeave implements LeaveRepository {
  int fetchCount = 0;
  List<LeaveRequest> rows = const [];

  @override
  Future<Sourced<List<LeaveRequest>>> fetchAll() async {
    fetchCount++;
    await Future<void>.delayed(_latency);
    return Sourced(rows, DataSource.live);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _seed = <ApprovalRequest>[
  ApprovalRequest(
    id: 'req-1',
    category: ApprovalCategory.academic,
    title: 'Curriculum Revision',
    requesterName: 'Dr. A. Kumar',
    requesterRole: 'HOD',
    departmentCode: 'CSE',
    submittedAt: DateTime(2026, 8, 1),
    summary: 'Revision to the fifth semester syllabus',
    priority: ApprovalPriority.routine,
    decision: ApprovalDecision.pending,
  ),
];

final _afterDatabaseChanged = <ApprovalRequest>[
  ..._seed,
  ApprovalRequest(
    id: 'req-2',
    category: ApprovalCategory.event,
    title: 'Annual Sports Meet',
    requesterName: 'Dr. B. Selvi',
    requesterRole: 'HOD',
    departmentCode: 'ECE',
    submittedAt: DateTime(2026, 8, 9),
    summary: 'Three-day inter-department meet',
    priority: ApprovalPriority.high,
    decision: ApprovalDecision.pending,
  ),
];

ProviderContainer _container(_CountingApprovals a, _CountingLeave l) {
  final container = ProviderContainer(
    overrides: [
      approvalsRepositoryProvider.overrideWithValue(a),
      leaveRepositoryProvider.overrideWithValue(l),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Approvals refresh goes back to the database', () {
    test('refreshes both the approval queue and the leave queue', () async {
      final approvals = _CountingApprovals();
      final leave = _CountingLeave();
      final container = _container(approvals, leave);

      // Keep both alive, as the screen's tabs do.
      container.listen(approvalRequestsProvider, (_, _) {});
      container.listen(leaveSourcedProvider, (_, _) {});
      await container.read(approvalRequestsProvider.future);
      await container.read(leaveSourcedProvider.future);

      expect(approvals.fetchCount, 1);
      expect(leave.fetchCount, 1);

      await container.read(approvalsRefreshProvider.notifier).run();

      // Both, not just the tab in view: the sidebar's pending badge counts
      // approvals and leave together.
      expect(approvals.fetchCount, 2, reason: 'approval queue was refetched');
      expect(leave.fetchCount, 2, reason: 'leave queue was refetched');
    });

    test('the UI value follows a change made in the database', () async {
      final approvals = _CountingApprovals();
      final container = _container(approvals, _CountingLeave());

      container.listen(approvalRequestsProvider, (_, _) {});
      await container.read(approvalRequestsProvider.future);
      expect(container.read(pendingApprovalsProvider), hasLength(1));

      // Stand in for another actor inserting a row between refreshes.
      approvals.rows = _afterDatabaseChanged;

      await container.read(approvalsRefreshProvider.notifier).run();

      expect(
        container.read(pendingApprovalsProvider),
        hasLength(2),
        reason: 'refresh must show the latest database state, not a cache',
      );
    });

    test('two concurrent triggers issue only one fetch each', () async {
      final approvals = _CountingApprovals();
      final leave = _CountingLeave();
      final container = _container(approvals, leave);

      container.listen(approvalRequestsProvider, (_, _) {});
      container.listen(leaveSourcedProvider, (_, _) {});
      await container.read(approvalRequestsProvider.future);
      await container.read(leaveSourcedProvider.future);

      final notifier = container.read(approvalsRefreshProvider.notifier);

      // The button and a pull gesture landing together.
      await Future.wait([notifier.run(), notifier.run(), notifier.run()]);

      expect(
        approvals.fetchCount,
        2,
        reason: 'three triggers must not produce three round trips',
      );
      expect(leave.fetchCount, 2);
    });

    test('a second refresh after the first settles does fetch again', () async {
      final approvals = _CountingApprovals();
      final container = _container(approvals, _CountingLeave());

      container.listen(approvalRequestsProvider, (_, _) {});
      await container.read(approvalRequestsProvider.future);

      final notifier = container.read(approvalsRefreshProvider.notifier);
      await notifier.run();
      await notifier.run();

      expect(
        approvals.fetchCount,
        3,
        reason: 'dedupe must not latch and block later refreshes',
      );
    });

    test(
      'the in-flight flag is raised while running and lowered after',
      () async {
        final container = _container(_CountingApprovals(), _CountingLeave());
        container.listen(approvalRequestsProvider, (_, _) {});
        container.listen(leaveSourcedProvider, (_, _) {});
        await container.read(approvalRequestsProvider.future);

        expect(container.read(approvalsRefreshProvider), isFalse);

        final running = container.read(approvalsRefreshProvider.notifier).run();
        expect(
          container.read(approvalsRefreshProvider),
          isTrue,
          reason: 'progress state must be observable while fetching',
        );

        await running;
        expect(container.read(approvalsRefreshProvider), isFalse);
      },
    );

    test('a failing fetch lowers the flag and does not throw out', () async {
      final container = ProviderContainer(
        overrides: [
          approvalsRepositoryProvider.overrideWithValue(_FailingApprovals()),
          leaveRepositoryProvider.overrideWithValue(_CountingLeave()),
        ],
      );
      addTearDown(container.dispose);

      // Must not throw: the error is carried by the provider and rendered by
      // the tab, so rethrowing here would report the same failure twice.
      await expectLater(
        container.read(approvalsRefreshProvider.notifier).run(),
        completes,
      );
      expect(container.read(approvalsRefreshProvider), isFalse);
      expect(container.read(approvalRequestsProvider).hasError, isTrue);
    });
  });

  group('Refresh button', () {
    testWidgets('shows progress and disables itself while refreshing', (
      tester,
    ) async {
      final approvals = _CountingApprovals();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            approvalsRepositoryProvider.overrideWithValue(approvals),
            leaveRepositoryProvider.overrideWithValue(_CountingLeave()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: ApprovalsRefreshButton())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(ApprovalsRefreshButton));
      await tester.pump();

      expect(find.text('Refreshing…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
        reason: 'the button is disabled while its fetch is in flight',
      );

      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

class _FailingApprovals implements ApprovalsRepository {
  @override
  Future<Sourced<List<ApprovalRequest>>> fetchAll() async {
    await Future<void>.delayed(_latency);
    throw StateError('No database connection for principal.approval_requests.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
