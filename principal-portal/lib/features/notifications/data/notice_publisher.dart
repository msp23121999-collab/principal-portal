import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/reference_sequence.dart';
import '../models/app_notification.dart';
import 'notice_delivery.dart';

enum NoticeAudience {
  everyone,
  students,
  faculty,
  department,
  program,
  year,
  batch,
}

extension NoticeAudienceX on NoticeAudience {
  String get label {
    switch (this) {
      case NoticeAudience.everyone:
        return 'Entire Institution';
      case NoticeAudience.students:
        return 'Students';
      case NoticeAudience.faculty:
        return 'Faculty';
      case NoticeAudience.department:
        return 'Department';
      case NoticeAudience.program:
        return 'Program';
      case NoticeAudience.year:
        return 'Year';
      case NoticeAudience.batch:
        return 'Batch';
    }
  }
}

enum NoticePriority { normal, important, urgent }

extension NoticePriorityX on NoticePriority {
  String get label {
    switch (this) {
      case NoticePriority.normal:
        return 'Normal';
      case NoticePriority.important:
        return 'Important';
      case NoticePriority.urgent:
        return 'Urgent';
    }
  }
}

class NoticeDraft {
  const NoticeDraft({
    required this.title,
    required this.body,
    required this.category,
    required this.audience,
    this.department,
    this.program,
    this.year,
    this.batch,
    this.priority = NoticePriority.normal,
    this.expiresAt,
  });

  final String title;
  final String body;
  final NotificationCategory category;
  final NoticeAudience audience;
  final String? department;
  final String? program;
  final String? year;
  final String? batch;
  final NoticePriority priority;
  final DateTime? expiresAt;
}

/// One write in a publish plan: which feed, and exactly what goes into it.
///
/// Separating the payload from the network call is what makes the targeting
/// testable. The columns are another team's, so a test that asserts on this
/// object is asserting the contract we send them — which is the thing that was
/// wrong, and the thing that could silently go wrong again.
@immutable
class PlannedWrite {
  const PlannedWrite({
    required this.channel,
    required this.schema,
    required this.table,
    required this.values,
  });

  final NoticeChannel channel;
  final String schema;
  final String table;
  final Map<String, dynamic> values;
}

/// What actually happened when a notice was published.
///
/// The three writes reach three schemas and cannot be wrapped in one
/// transaction from the client, so "it worked" is not a yes/no answer. This
/// carries the real one, and [message] states it in the words the Principal
/// needs — a notice that reached staff but not students has to say so rather
/// than report success.
@immutable
class NoticePublishOutcome {
  const NoticePublishOutcome({
    required this.delivered,
    required this.failed,
    required this.asDraft,
  });

  /// Feeds the notice reached, including the noticeboard itself.
  final List<NoticeChannel> delivered;

  /// Feeds that refused it, and why. Never empty on a partial publish.
  final Map<NoticeChannel, String> failed;

  final bool asDraft;

  bool get isComplete => failed.isEmpty;

  /// True when the notice is on the noticeboard but did not reach every
  /// recipient feed. This is the state that used to be reported as success.
  bool get isPartial => failed.isNotEmpty;

  /// Plain-language result, safe to put straight into a snackbar.
  ///
  /// Names the audience, not the table, and never claims a delivery that did
  /// not happen.
  String get message {
    if (asDraft) return 'Notice saved as draft. It has not been sent.';
    if (isComplete) return 'Notice published.';

    final missed = failed.keys.map((c) => c.label).join(' and ');
    return 'Notice saved to the noticeboard, but it did not reach $missed. '
        'Those recipients have not seen it — try publishing again.';
  }
}

class NoticePublisher {
  /// Builds the exact set of writes a draft turns into.
  ///
  /// Pure: no clock, no network, no identity lookup — [now], [author] and
  /// [reference] are supplied. That is what lets a test assert the payload
  /// sent to another team's table without a database.
  ///
  /// The feeds included come from [NoticeAudienceDelivery.channels], so the
  /// dialog and the publisher cannot disagree about who receives what.
  @visibleForTesting
  static List<PlannedWrite> planFor(
    NoticeDraft draft, {
    required String author,
    required DateTime now,
    required String reference,
    bool asDraft = false,
  }) {
    if (!draft.audience.isDeliverable) {
      throw UndeliverableAudience(draft.audience);
    }

    final circularAudience = switch (draft.audience) {
      NoticeAudience.faculty => 'faculty',
      NoticeAudience.students => 'students',
      NoticeAudience.batch => 'students',
      NoticeAudience.year => 'students',
      NoticeAudience.program => 'students',
      _ => 'everyone',
    };

    final circularCategory = switch (draft.category) {
      NotificationCategory.academic => 'academic',
      NotificationCategory.emergency => 'urgent',
      NotificationCategory.circular => 'administrative',
      NotificationCategory.announcement => 'event',
    };

    final priorityLabel = switch (draft.priority) {
      NoticePriority.normal => 'normal',
      NoticePriority.important => 'important',
      NoticePriority.urgent => 'urgent',
    };

    // The noticeboard is ours and carries every targeting axis, including the
    // two no feed can deliver. That is deliberate: the record of what the
    // Principal addressed it to stays complete even where delivery cannot.
    final writes = <PlannedWrite>[
      PlannedWrite(
        channel: NoticeChannel.noticeboard,
        schema: DbSchema.principal,
        table: 'circulars',
        values: {
          'reference': reference,
          'title': draft.title,
          'body': draft.body,
          'category': circularCategory,
          'audience': circularAudience,
          'status': asDraft ? 'draft' : 'published',
          'author_name': author,
          'priority': priorityLabel,
          'department_code': draft.department,
          'program_level': draft.program,
          'year_of_study': draft.year,
          'batch': draft.batch,
          if (!asDraft) 'published_at': now.toIso8601String(),
          if (draft.expiresAt != null)
            'expires_at': draft.expiresAt!.toIso8601String(),
        },
      ),
    ];

    // A draft is filed, not sent.
    if (asDraft) return writes;

    final channels = draft.audience.channels;

    if (channels.contains(NoticeChannel.facultyFeed)) {
      writes.add(
        PlannedWrite(
          channel: NoticeChannel.facultyFeed,
          schema: DbSchema.faculty,
          table: 'notifications',
          values: {
            'faculty_employee_id': 'ALL',
            'title': draft.title,
            'description': draft.body,
            'category': draft.category.label,
            'tag': draft.category.label,
            'priority': draft.priority.label.toUpperCase(),
            'source': 'Principal Office',
            'type': draft.category.label.toUpperCase(),
            'role': 'all',
            // Their table narrows on these two and nothing else.
            'department': draft.department,
            'target_batch': draft.batch ?? 'All Batches',
          },
        ),
      );
    }

    if (channels.contains(NoticeChannel.studentFeed)) {
      writes.add(
        PlannedWrite(
          channel: NoticeChannel.studentFeed,
          schema: DbSchema.student,
          table: 'student_notifications',
          values: {
            'student_id': 'ALL',
            'title': draft.title,
            'description': draft.body,
            'category': draft.category.label.toUpperCase(),
            // `batch` is the only axis their table can narrow on. Department,
            // programme and year are absent by design, not by omission — an
            // audience needing them never reaches this branch.
            'batch': draft.batch ?? 'All Batches',
            'priority': draft.priority.label.toUpperCase(),
          },
        ),
      );
    }

    return writes;
  }

  /// Publishes [draft] and reports, per feed, what landed.
  ///
  /// The noticeboard write goes first and is mandatory: if the portal cannot
  /// record the notice it has not published anything, so that failure throws
  /// rather than being folded into a partial result. Every recipient feed after
  /// it is attempted independently — one portal being unreachable must not stop
  /// the notice reaching the other — and each failure is collected.
  ///
  /// This is not a transaction, and it cannot be from the client: the three
  /// tables sit in three schemas owned by three teams. What it guarantees is
  /// that a partial delivery is *reported* as one. See
  /// `docs/principal-integration/FINAL-PRINCIPAL-PORTAL-HARDENING-QA.md`,
  /// ISSUE 04, for the transactional design this would need.
  Future<NoticePublishOutcome> publish(
    NoticeDraft draft, {
    bool asDraft = false,
  }) async {
    if (!ApiClient.isReady) {
      throw StateError(
        'Cannot publish a notice — no database connection. The portal is '
        'running without a backend.',
      );
    }

    final now = DateTime.now();
    final author = 'Principal';

    // Validate before writing anything, so an undeliverable audience cannot
    // leave a noticeboard row behind.
    if (!draft.audience.isDeliverable) {
      throw UndeliverableAudience(draft.audience);
    }

    final delivered = <NoticeChannel>[];
    final failed = <NoticeChannel, String>{};

    // 1. The record. `circulars.reference` is uniquely indexed, so a
    //    simultaneous publish collides rather than duplicating; the reference
    //    is recomputed and retried instead of losing the notice.
    late List<PlannedWrite> plan;
    await ReferenceSequence.insertWithRetry(
      nextReference: () => _nextReference(now.year),
      insert: (reference) async {
        plan = planFor(
          draft,
          author: author,
          now: now,
          reference: reference,
          asDraft: asDraft,
        );
        final record = plan.first;
        await ApiClient.schema(
          record.schema,
        ).from(record.table).insert(record.values);
      },
    );
    delivered.add(NoticeChannel.noticeboard);

    // 2. The recipient feeds, each independent of the other.
    for (final write in plan.skip(1)) {
      try {
        await ApiClient.schema(
          write.schema,
        ).from(write.table).insert(write.values);
        delivered.add(write.channel);
      } catch (error) {
        // The reason is kept for the Principal in general terms only. The
        // driver message names another team's schema and table, which is not
        // something to put on screen.
        failed[write.channel] = 'The request was refused.';
        if (kDebugMode) {
          debugPrint('Notice delivery failed (${write.channel.name}): $error');
        }
      }
    }

    return NoticePublishOutcome(
      delivered: delivered,
      failed: failed,
      asDraft: asDraft,
    );
  }

  /// The next notice reference for [year].
  ///
  /// Only this year's notice references are considered, highest first, and only
  /// one row is fetched. Allocating the number in the database would remove the
  /// read-then-write race entirely and is recorded as a remaining dependency.
  Future<String> _nextReference(int year) async {
    final prefix = 'KSRCE/NOTICE/$year/';

    final rows = await ApiClient.schema(DbSchema.principal)
        .from('circulars')
        .select('reference')
        .like('reference', '$prefix%')
        .order('reference', ascending: false)
        .limit(1);

    var next = 1;
    if (rows.isNotEmpty) {
      final last = rows.first['reference'] as String?;
      next = (int.tryParse(last?.split('/').last ?? '') ?? 0) + 1;
    }

    return '$prefix${next.toString().padLeft(3, '0')}';
  }
}

final noticePublisherProvider = Provider((ref) => NoticePublisher());
