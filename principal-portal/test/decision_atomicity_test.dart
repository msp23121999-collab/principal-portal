import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';
import 'package:principal_portal/features/approvals/data/approvals_repository.dart';
import 'package:principal_portal/features/notifications/data/notice_delivery.dart';
import 'package:principal_portal/features/notifications/data/notice_publisher.dart';

import 'fixtures/portal_fixtures.dart';

/// Cover for multi-write actions that can half-succeed.
///
/// Three flows write to more than one table with nothing tying the writes
/// together — an approval decision, a leave decision, and publishing a notice.
/// Every one of them reported success as soon as no exception escaped, so a
/// decision that applied without reaching the audit trail, and a notice that
/// reached staff but not students, both read as "done".
///
/// They cannot be made transactional from the client: the notice spans three
/// schemas owned by three teams, and the leave decision spans two. What is
/// guaranteed instead — and asserted here — is that a partial result is
/// reported as a partial result.
void main() {
  const surface = Size(1600, 1400);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    bool auditTrailFails = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() {
      tester.view.reset();
      return tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: portalOverrides(auditTrailFails: auditTrailFails),
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
  // The outcome types themselves
  // ---------------------------------------------------------------------------

  group('a decision states whether it was recorded', () {
    test('a recorded decision says so plainly', () {
      const outcome = DecisionOutcome(recorded: true);
      expect(outcome.message, 'Decision recorded.');
    });

    test('an unrecorded decision never claims the trail has it', () {
      const outcome = DecisionOutcome(
        recorded: false,
        auditError: 'The audit trail refused the entry.',
      );

      expect(outcome.message, contains('could not be written'));
      expect(
        outcome.message,
        contains('administrator'),
        reason: 'A missing audit entry needs someone told, not just a toast.',
      );
      // The decision itself did apply. Telling the Principal it failed would
      // invite them to repeat it, applying it twice.
      expect(outcome.message, contains('was applied'));
    });
  });

  group('a publish states which feeds it reached', () {
    test('all feeds reached reports a clean publish', () {
      const outcome = NoticePublishOutcome(
        delivered: [
          NoticeChannel.noticeboard,
          NoticeChannel.facultyFeed,
          NoticeChannel.studentFeed,
        ],
        failed: {},
        asDraft: false,
      );

      expect(outcome.isComplete, isTrue);
      expect(outcome.isPartial, isFalse);
      expect(outcome.message, 'Notice published.');
    });

    test('a feed that refused is named, and success is not claimed', () {
      const outcome = NoticePublishOutcome(
        delivered: [NoticeChannel.noticeboard, NoticeChannel.facultyFeed],
        failed: {NoticeChannel.studentFeed: 'The request was refused.'},
        asDraft: false,
      );

      expect(outcome.isComplete, isFalse);
      expect(outcome.isPartial, isTrue);
      expect(outcome.message, contains('the Student Portal'));
      expect(
        outcome.message.contains('published.'),
        isFalse,
        reason:
            'This is the message that used to read "published successfully".',
      );
      expect(outcome.message, contains('have not seen it'));
    });

    test('two failed feeds are both named', () {
      const outcome = NoticePublishOutcome(
        delivered: [NoticeChannel.noticeboard],
        failed: {
          NoticeChannel.facultyFeed: 'The request was refused.',
          NoticeChannel.studentFeed: 'The request was refused.',
        },
        asDraft: false,
      );

      expect(outcome.message, contains('the Faculty Portal'));
      expect(outcome.message, contains('the Student Portal'));
    });

    test('a draft says it has not been sent', () {
      const outcome = NoticePublishOutcome(
        delivered: [NoticeChannel.noticeboard],
        failed: {},
        asDraft: true,
      );

      expect(outcome.message, contains('has not been sent'));
    });

    test('no message leaks a schema or table name', () {
      // partialWarning elsewhere in the portal is careful about this; these
      // messages are shown in the same places and must be too.
      const outcome = NoticePublishOutcome(
        delivered: [NoticeChannel.noticeboard],
        failed: {NoticeChannel.studentFeed: 'The request was refused.'},
        asDraft: false,
      );

      for (final leak in const [
        'student_notifications',
        'faculty.notifications',
        'circulars',
        'principal.',
        'PostgrestException',
      ]) {
        expect(outcome.message, isNot(contains(leak)));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // The screens
  // ---------------------------------------------------------------------------

  group('the Approvals screen reports what actually happened', () {
    testWidgets('a fully recorded decision reports success', (tester) async {
      await pumpApp(tester);
      await open(tester, 'Approvals');

      await tester.tap(find.text('Approve').first);
      await settle(tester);
      await tester.tap(find.text('Confirm Approval'));
      await settle(tester);

      expect(find.textContaining('approved.'), findsWidgets);
      expect(find.textContaining('audit trail did not record'), findsNothing);
    });

    testWidgets('a decision the trail refused is not reported as clean', (
      tester,
    ) async {
      await pumpApp(tester, auditTrailFails: true);
      await open(tester, 'Approvals');

      await tester.tap(find.text('Approve').first);
      await settle(tester);
      await tester.tap(find.text('Confirm Approval'));
      await settle(tester);

      expect(
        find.textContaining('audit trail did not record it'),
        findsOneWidget,
        reason:
            'The decision applied and the trail did not take it. Saying only '
            '"approved." is the defect.',
      );
    });

    testWidgets('the queue still refreshes when the trail write fails', (
      tester,
    ) async {
      // The decision took effect either way, so a queue still offering to
      // approve it would be wrong in the more dangerous direction — the
      // Principal could apply the same decision twice.
      await pumpApp(tester, auditTrailFails: true);
      await open(tester, 'Approvals');

      final before = tester.widgetList(find.text('Approve')).length;
      expect(before, greaterThan(0));

      await tester.tap(find.text('Approve').first);
      await settle(tester);
      await tester.tap(find.text('Confirm Approval'));
      await settle(tester);

      expect(
        tester.widgetList(find.text('Approve')).length,
        lessThan(before),
        reason:
            'The list must reflect the decision that was applied, even though '
            'the audit entry for it failed.',
      );
    });
  });
}
