import 'notice_publisher.dart';

/// Where a published notice actually lands.
///
/// Three destinations, owned by three different teams:
///
///  * [noticeboard] — `principal.circulars`. Ours. Carries the full targeting.
///  * [facultyFeed] — `faculty.notifications`. The Faculty Portal's.
///  * [studentFeed] — `student.student_notifications`. The Student Portal's.
enum NoticeChannel { noticeboard, facultyFeed, studentFeed }

extension NoticeChannelX on NoticeChannel {
  /// Wording for a message the Principal reads. Never a table name.
  String get label {
    switch (this) {
      case NoticeChannel.noticeboard:
        return 'the institutional noticeboard';
      case NoticeChannel.facultyFeed:
        return 'the Faculty Portal';
      case NoticeChannel.studentFeed:
        return 'the Student Portal';
    }
  }
}

/// What each downstream feed can actually narrow a notice by.
///
/// ## Why this file exists
///
/// The publish dialog offered seven audiences — including Programme and Year —
/// and the publisher then pushed every student-facing notice into
/// `student.student_notifications` carrying only `batch`. A notice addressed to
/// "CSE, III Year" therefore reached *every student in the institution*, and
/// nothing said so: the Principal saw "Notice published successfully".
///
/// The columns were confirmed against the live project on 2026-08-15 by
/// requesting each candidate column with `limit=0`, which returns either an
/// empty array (the column exists) or SQLSTATE 42703 (it does not). No row was
/// read and nothing was written.
///
/// ```
///   student.student_notifications
///     id, student_id, title, description, category, batch, priority, created_at
///     -> narrows by BATCH only
///
///   faculty.notifications
///     id, faculty_employee_id, title, description, category, tag, priority,
///     source, type, role, department, target_batch, created_at
///     -> narrows by DEPARTMENT and BATCH
/// ```
///
/// Neither feed has a programme or year-of-study column. Those two axes are
/// therefore undeliverable to anybody, and the portal no longer offers them —
/// see [NoticeAudienceDelivery.isDeliverable].
///
/// Adding the missing columns is the Student Portal team's decision about
/// their own table, not ours. Until they do, this map is the honest statement
/// of what the system can enforce, and both the dialog and the publisher read
/// it rather than each deciding for themselves.
extension NoticeAudienceDelivery on NoticeAudience {
  /// The feeds that can carry this audience **without widening it**.
  ///
  /// A feed is listed only when it can either deliver to everyone it should, or
  /// narrow to exactly the group named. A feed that would have to broadcast
  /// wider than the Principal asked is left out — over-delivery is the defect
  /// this replaces, not an acceptable approximation of it.
  Set<NoticeChannel> get channels {
    switch (this) {
      case NoticeAudience.everyone:
        return const {
          NoticeChannel.noticeboard,
          NoticeChannel.facultyFeed,
          NoticeChannel.studentFeed,
        };
      case NoticeAudience.students:
        return const {NoticeChannel.noticeboard, NoticeChannel.studentFeed};
      case NoticeAudience.faculty:
        return const {NoticeChannel.noticeboard, NoticeChannel.facultyFeed};

      // faculty.notifications has a `department` column; the student feed has
      // nothing to narrow on, so students are deliberately not included. The
      // notice is still recorded on the noticeboard with its department.
      case NoticeAudience.department:
        return const {NoticeChannel.noticeboard, NoticeChannel.facultyFeed};

      // Both feeds carry a batch: `batch` on the student side, `target_batch`
      // on the faculty side.
      case NoticeAudience.batch:
        return const {
          NoticeChannel.noticeboard,
          NoticeChannel.facultyFeed,
          NoticeChannel.studentFeed,
        };

      // No feed can narrow by programme or year of study.
      case NoticeAudience.program:
      case NoticeAudience.year:
        return const {NoticeChannel.noticeboard};
    }
  }

  /// Whether the portal may offer this audience at all.
  ///
  /// False for the two axes that reach no recipient. A notice that is filed and
  /// delivered to nobody is worse than one the Principal was never invited to
  /// write, because it looks sent.
  bool get isDeliverable => channels.any((c) => c != NoticeChannel.noticeboard);

  /// One sentence stating exactly who receives this, shown in the dialog.
  ///
  /// Written for the Principal, so it names people rather than tables, and it
  /// says what will *not* happen where that is the surprising part.
  String get deliverySummary {
    switch (this) {
      case NoticeAudience.everyone:
        return 'Every student and every member of staff.';
      case NoticeAudience.students:
        return 'Every student.';
      case NoticeAudience.faculty:
        return 'Every member of staff.';
      case NoticeAudience.department:
        return 'Staff in the selected department. Students are not included — '
            'the Student Portal feed cannot be narrowed by department.';
      case NoticeAudience.batch:
        return 'Students in the selected batch, and staff assigned to it.';
      case NoticeAudience.program:
      case NoticeAudience.year:
        return 'Nobody. This portal cannot deliver to that group.';
    }
  }

  /// The audiences the publish dialog is allowed to offer.
  static List<NoticeAudience> get selectable =>
      NoticeAudience.values.where((a) => a.isDeliverable).toList();
}

/// Raised when a notice is published to an audience no feed can carry.
///
/// The dialog cannot produce one — it builds its list from
/// [NoticeAudienceDelivery.selectable] — so reaching this means a caller
/// constructed a draft directly. It fails loudly rather than writing the
/// noticeboard row and quietly delivering to nobody.
class UndeliverableAudience implements Exception {
  const UndeliverableAudience(this.audience);

  final NoticeAudience audience;

  @override
  String toString() =>
      'A notice cannot be addressed to "${audience.label}": no recipient feed '
      'can be narrowed to that group.';
}
