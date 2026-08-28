import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/features/notifications/data/notice_delivery.dart';
import 'package:principal_portal/features/notifications/data/notice_publisher.dart';
import 'package:principal_portal/features/notifications/models/app_notification.dart';

/// Cover for the targeting a published notice actually carries.
///
/// The publish dialog offered seven audiences. The publisher pushed every
/// student-facing notice into `student.student_notifications` with only
/// `batch` set, so a notice addressed to one department reached every student
/// in the institution — and the Principal was told it published successfully.
///
/// The recipient tables belong to other teams, so what is asserted here is the
/// *payload we send them*: the contract that was wrong, and the one that can
/// silently go wrong again. Column availability was confirmed against the live
/// project on 2026-08-15 with `limit=0` probes, which return an empty array or
/// SQLSTATE 42703 without reading a row.
void main() {
  final now = DateTime.utc(2026, 8, 15, 9, 30);

  NoticeDraft draft({
    required NoticeAudience audience,
    String? department,
    String? batch,
  }) => NoticeDraft(
    title: 'Semester review meeting',
    body: 'All concerned are requested to attend.',
    category: NotificationCategory.announcement,
    audience: audience,
    department: department,
    batch: batch,
  );

  List<PlannedWrite> plan(NoticeDraft d, {bool asDraft = false}) =>
      NoticePublisher.planFor(
        d,
        author: 'Dr. S. Venkataraman',
        now: now,
        reference: 'KSRCE/NOTICE/2026/001',
        asDraft: asDraft,
      );

  PlannedWrite? writeFor(List<PlannedWrite> writes, NoticeChannel channel) {
    for (final w in writes) {
      if (w.channel == channel) return w;
    }
    return null;
  }

  group('what each audience is allowed to promise', () {
    test(
      'programme and year are never offered — no feed can narrow by them',
      () {
        expect(
          NoticeAudienceDelivery.selectable,
          isNot(contains(NoticeAudience.program)),
        );
        expect(
          NoticeAudienceDelivery.selectable,
          isNot(contains(NoticeAudience.year)),
        );

        expect(NoticeAudience.program.isDeliverable, isFalse);
        expect(NoticeAudience.year.isDeliverable, isFalse);
      },
    );

    test('the audiences that do reach somebody are all still offered', () {
      expect(
        NoticeAudienceDelivery.selectable,
        containsAll(<NoticeAudience>[
          NoticeAudience.everyone,
          NoticeAudience.students,
          NoticeAudience.faculty,
          NoticeAudience.department,
          NoticeAudience.batch,
        ]),
      );
    });

    test('the dialog builds its list from the capability map, not the enum', () {
      // A regression here is invisible at runtime until someone publishes to a
      // group that receives nothing, so it is caught in the source instead.
      final source = File(
        'lib/features/notifications/widgets/create_notice_dialog.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('NoticeAudienceDelivery.selectable'),
        reason: 'The audience dropdown must read the capability map.',
      );
      expect(
        source.contains('items: NoticeAudience.values'),
        isFalse,
        reason:
            'Offering every enum value is what put Programme and Year in front '
            'of the Principal when neither could be delivered.',
      );
    });

    test(
      'an undeliverable audience fails loudly rather than filing quietly',
      () {
        expect(
          () => plan(draft(audience: NoticeAudience.year)),
          throwsA(isA<UndeliverableAudience>()),
        );
      },
    );
  });

  group('batch targeting is preserved on every feed that carries it', () {
    test('the student feed receives the batch', () {
      final writes = plan(
        draft(audience: NoticeAudience.batch, batch: '2022-2026'),
      );
      final student = writeFor(writes, NoticeChannel.studentFeed);

      expect(student, isNotNull);
      expect(student!.table, 'student_notifications');
      expect(student.values['batch'], '2022-2026');
    });

    test('the faculty feed receives the same batch in its own column', () {
      final writes = plan(
        draft(audience: NoticeAudience.batch, batch: '2022-2026'),
      );
      final faculty = writeFor(writes, NoticeChannel.facultyFeed);

      expect(faculty, isNotNull);
      expect(faculty!.values['target_batch'], '2022-2026');
    });

    test('the noticeboard records it too', () {
      final writes = plan(
        draft(audience: NoticeAudience.batch, batch: '2022-2026'),
      );
      final board = writeFor(writes, NoticeChannel.noticeboard);

      expect(board!.values['batch'], '2022-2026');
    });
  });

  group('department targeting is preserved where it is supported', () {
    test('the faculty feed receives the department', () {
      final writes = plan(
        draft(audience: NoticeAudience.department, department: 'CSE'),
      );
      final faculty = writeFor(writes, NoticeChannel.facultyFeed);

      expect(faculty, isNotNull);
      expect(faculty!.values['department'], 'CSE');
    });

    test('the student feed is not written at all', () {
      // This is the defect. `student.student_notifications` has no department
      // column, so the old code sent the notice to every student rather than
      // to none. Widening the audience without saying so is worse than not
      // delivering: the Principal believed it was narrowed.
      final writes = plan(
        draft(audience: NoticeAudience.department, department: 'CSE'),
      );

      expect(
        writeFor(writes, NoticeChannel.studentFeed),
        isNull,
        reason:
            'A department notice must not be broadcast to the whole student '
            'roll just because the feed cannot narrow.',
      );
    });

    test('the noticeboard still records the department in full', () {
      final writes = plan(
        draft(audience: NoticeAudience.department, department: 'CSE'),
      );

      expect(
        writeFor(writes, NoticeChannel.noticeboard)!.values['department_code'],
        'CSE',
        reason: 'What it was addressed to stays on the record either way.',
      );
    });

    test('the Principal is told students are excluded', () {
      expect(
        NoticeAudience.department.deliverySummary,
        contains('Students are not included'),
      );
    });
  });

  group('the untargeted audiences reach the right feeds', () {
    test('entire institution reaches both portals', () {
      final writes = plan(draft(audience: NoticeAudience.everyone));
      expect(writes.map((w) => w.channel), containsAll(NoticeChannel.values));
    });

    test('students only reaches the student portal', () {
      final writes = plan(draft(audience: NoticeAudience.students));
      expect(writeFor(writes, NoticeChannel.studentFeed), isNotNull);
      expect(writeFor(writes, NoticeChannel.facultyFeed), isNull);
    });

    test('faculty only reaches the faculty portal', () {
      final writes = plan(draft(audience: NoticeAudience.faculty));
      expect(writeFor(writes, NoticeChannel.facultyFeed), isNotNull);
      expect(writeFor(writes, NoticeChannel.studentFeed), isNull);
    });

    test('a draft is filed and sent to nobody', () {
      final writes = plan(
        draft(audience: NoticeAudience.everyone),
        asDraft: true,
      );

      expect(writes.length, 1);
      expect(writes.single.channel, NoticeChannel.noticeboard);
      expect(writes.single.values['status'], 'draft');
      expect(writes.single.values.containsKey('published_at'), isFalse);
    });
  });

  group('no invented columns reach another team\'s table', () {
    // The Student Portal owns its feed. Sending a column it does not have is
    // a failed insert at best; inventing one to make targeting "work" is the
    // failure mode this guards.
    const studentColumns = {
      'student_id',
      'title',
      'description',
      'category',
      'batch',
      'priority',
    };
    const facultyColumns = {
      'faculty_employee_id',
      'title',
      'description',
      'category',
      'tag',
      'priority',
      'source',
      'type',
      'role',
      'department',
      'target_batch',
    };

    test('the student payload uses only columns that exist', () {
      for (final audience in NoticeAudienceDelivery.selectable) {
        final student = writeFor(
          plan(
            draft(audience: audience, department: 'CSE', batch: '2022-2026'),
          ),
          NoticeChannel.studentFeed,
        );
        if (student == null) continue;
        expect(
          student.values.keys.toSet().difference(studentColumns),
          isEmpty,
          reason: 'Unknown column sent for audience ${audience.label}.',
        );
      }
    });

    test('the faculty payload uses only columns that exist', () {
      for (final audience in NoticeAudienceDelivery.selectable) {
        final faculty = writeFor(
          plan(
            draft(audience: audience, department: 'CSE', batch: '2022-2026'),
          ),
          NoticeChannel.facultyFeed,
        );
        if (faculty == null) continue;
        expect(
          faculty.values.keys.toSet().difference(facultyColumns),
          isEmpty,
          reason: 'Unknown column sent for audience ${audience.label}.',
        );
      }
    });
  });
}
