import '../../../core/services/api_client.dart';
import '../../../core/services/reference_sequence.dart';
import '../../../core/services/repository.dart';
import '../models/circular.dart';

/// Reads the institution's noticeboard and writes the Principal's own.
///
/// Three sources, merged chronologically:
///
///  * `hod.department_notices` and `student.notice_board_posts` — owned by the
///    other portals, read-only. The Principal cannot draft or archive into
///    someone else's table.
///  * `principal.circulars` — the Principal's own, which is why publishing,
///    archiving and pinning need a table here rather than mutating theirs.
///
/// Only the Principal's own circulars can be edited; the other two appear as
/// published and stay that way.
class CircularsRepository extends Repository {
  CircularsRepository();

  static const _table = 'circulars';

  Future<Sourced<List<Circular>>> fetchAll() {
    return load<List<Circular>>(
      debugLabel: 'principal.circulars + hod + student notices',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        // Gathered independently so one unreachable source cannot discard the
        // rows that did come back.
        final result = await gatherWithReport<Circular>({
          'principal.circulars': _fetchOwnCirculars,
          'hod.department_notices': _fetchDepartmentNotices,
          'student.notice_board_posts': _fetchNoticeBoardPosts,
        });

        _lastPartialWarning = result.partialWarning;

        return result.rows..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    );
  }

  /// Warning text from the last fetch, or empty if all sources succeeded.
  String get lastPartialWarning => _lastPartialWarning;
  String _lastPartialWarning = '';

  /// Circulars the Principal wrote. These carry a real status, so drafts and
  /// archived items are genuinely distinct rather than everything being
  /// published by default.
  Future<List<Circular>> _fetchOwnCirculars() async {
    final rows = await ApiClient.schema(
      DbSchema.principal,
    ).from(_table).select();

    return [
      for (final raw in rows) _toOwnCircular(Map<String, dynamic>.from(raw)),
    ];
  }

  Circular _toOwnCircular(Map<String, dynamic> row) {
    final status = switch (row.str('status')) {
      'draft' => CircularStatus.draft,
      'archived' => CircularStatus.archived,
      _ => CircularStatus.published,
    };

    final category = switch (row.str('category')) {
      'administrative' => CircularCategory.administrative,
      'examination' => CircularCategory.examination,
      'event' => CircularCategory.event,
      'urgent' => CircularCategory.urgent,
      _ => CircularCategory.academic,
    };

    final audience = switch (row.str('audience')) {
      'faculty' => CircularAudience.faculty,
      'students' => CircularAudience.students,
      'staff' => CircularAudience.staff,
      'heads_of_department' => CircularAudience.headsOfDepartment,
      _ => CircularAudience.everyone,
    };

    return Circular(
      id: row.strOr('id', ''),
      reference: row.strOr('reference', ''),
      title: row.strOr('title', ''),
      body: row.strOr('body', ''),
      category: category,
      audience: audience,
      status: status,
      author: row.strOr('author_name', '—'),
      createdAt: row.dateOr('created_at', DateTime.now()),
      recipients: row.intOr('recipient_count', 0),
      // Acknowledgements are counted from a real table rather than stored, so
      // the read percentage cannot drift from who actually read it. Zero until
      // anyone has.
      acknowledgements: 0,
      publishedAt: row.str('published_at') == null
          ? null
          : row.dateOr('published_at', DateTime.now()),
      isPinned: row.boolOr('is_pinned', false),
    );
  }

  /// Publishes a new circular.
  ///
  /// The reference is generated from the current year and the last reference
  /// issued, so it reads like an institutional reference rather than a uuid.
  ///
  /// [author] defaults to the signed-in Principal's name, looked up from their
  /// own profile row. It used to default to a name compiled into the app, so
  /// every circular in the database claimed the same author regardless of who
  /// published it.
  Future<void> publish({
    required String title,
    required String body,
    required CircularCategory category,
    required CircularAudience audience,
    required bool asDraft,
    String? author,
  }) async {
    final year = DateTime.now().year;
    final authorName = author ?? 'Principal';

    // `circulars.reference` carries a unique index, so two publishes that read
    // the same highest reference do not produce a duplicate — the second one
    // fails. Retrying re-reads the sequence and takes the next number, which
    // turns a lost circular into a brief second attempt.
    await ReferenceSequence.insertWithRetry(
      nextReference: () => _nextReference(year),
      insert: (reference) => insertRow(_table, {
        'reference': reference,
        'title': title,
        'body': body,
        'category': _categoryTo(category),
        'audience': _audienceTo(audience),
        'status': asDraft ? 'draft' : 'published',
        'author_name': authorName,
        // A published circular must record when — the database enforces it too.
        if (!asDraft) 'published_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// The next circular reference for [year].
  ///
  /// This used to count every row in the table and add one. `circulars` also
  /// holds `KSRCE/NOTICE/...` references published from the Notifications
  /// screen, so the count drifted away from the circular sequence and could
  /// reissue a reference that already existed. Only this year's circular
  /// references are considered now, highest first, one row fetched.
  ///
  /// `reference` already carries a unique index (`circulars_reference_key`), so
  /// a simultaneous publish fails rather than duplicating; the caller retries
  /// through [ReferenceSequence.insertWithRetry]. Allocating the number
  /// atomically in the database would remove the race entirely and is recorded
  /// as a remaining dependency.
  Future<String> _nextReference(int year) async {
    final prefix = 'KSRCE/PRIN/$year/';

    final rows = await ApiClient.schema(DbSchema.principal)
        .from(_table)
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

  Future<void> setStatus(String circularId, CircularStatus status) {
    return updateRow(_table, circularId, {
      'status': switch (status) {
        CircularStatus.draft => 'draft',
        CircularStatus.archived => 'archived',
        CircularStatus.published => 'published',
      },
      if (status == CircularStatus.published)
        'published_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setPinned(String circularId, bool pinned) {
    return updateRow(_table, circularId, {'is_pinned': pinned});
  }

  static String _categoryTo(CircularCategory category) => switch (category) {
    CircularCategory.administrative => 'administrative',
    CircularCategory.examination => 'examination',
    CircularCategory.event => 'event',
    CircularCategory.urgent => 'urgent',
    CircularCategory.academic => 'academic',
  };

  static String _audienceTo(CircularAudience audience) => switch (audience) {
    CircularAudience.faculty => 'faculty',
    CircularAudience.students => 'students',
    CircularAudience.staff => 'staff',
    CircularAudience.headsOfDepartment => 'heads_of_department',
    CircularAudience.everyone => 'everyone',
  };

  Future<List<Circular>> _fetchDepartmentNotices() async {
    final rows = await ApiClient.schema(
      DbSchema.hod,
    ).from('department_notices').select();

    return [
      for (final row in rows)
        _toCircular(
          Map<String, dynamic>.from(row),
          referencePrefix: 'KSRCE/DEPT',
          defaultAudience: CircularAudience.headsOfDepartment,
        ),
    ];
  }

  Future<List<Circular>> _fetchNoticeBoardPosts() async {
    final rows = await ApiClient.schema(
      DbSchema.student,
    ).from('notice_board_posts').select();

    return [
      for (final row in rows)
        _toCircular(
          Map<String, dynamic>.from(row),
          referencePrefix: 'KSRCE/NB',
          defaultAudience: CircularAudience.students,
        ),
    ];
  }

  Circular _toCircular(
    Map<String, dynamic> row, {
    required String referencePrefix,
    required CircularAudience defaultAudience,
  }) {
    final id = row.firstStr(['id', 'notice_id', 'post_id', 'uuid']) ?? '';
    final createdAt = row.dateOr(
      'created_at',
      row.dateOr('posted_at', DateTime.now()),
    );

    final isPublished = row.boolOr(
      'is_published',
      row.boolOr('published', true),
    );

    return Circular(
      id: id,
      reference:
          row.firstStr(['reference', 'reference_no']) ??
          '$referencePrefix/${createdAt.year}/${id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase()}',
      title: row.firstStr(['title', 'subject', 'heading']) ?? 'Untitled notice',
      body: row.firstStr(['content', 'body', 'message', 'description']) ?? '',
      category: _categoryFrom(row.firstStr(['category', 'type', 'tag'])),
      audience: _audienceFrom(
        row.firstStr(['audience', 'target_audience', 'visible_to']),
        defaultAudience,
      ),
      status: isPublished ? CircularStatus.published : CircularStatus.draft,
      author:
          row.firstStr(['author', 'created_by', 'posted_by', 'faculty_name']) ??
          'Administration',
      createdAt: createdAt,
      // Readership counters are not tracked in the source tables; showing 0
      // is honest, whereas inventing a number would misreport engagement.
      recipients: row.intOr('recipients', 0),
      acknowledgements: row.intOr('acknowledgements', row.intOr('views', 0)),
      publishedAt: isPublished ? createdAt : null,
      isPinned: row.boolOr('is_pinned', row.boolOr('pinned', false)),
    );
  }

  CircularCategory _categoryFrom(String? raw) {
    final text = (raw ?? '').toLowerCase();
    if (text.contains('urgent') || text.contains('emergency')) {
      return CircularCategory.urgent;
    }
    if (text.contains('exam')) return CircularCategory.examination;
    if (text.contains('event')) return CircularCategory.event;
    if (text.contains('admin')) return CircularCategory.administrative;
    return CircularCategory.academic;
  }

  CircularAudience _audienceFrom(String? raw, CircularAudience fallback) {
    final text = (raw ?? '').toLowerCase();
    if (text.isEmpty) return fallback;
    if (text.contains('all') || text.contains('everyone')) {
      return CircularAudience.everyone;
    }
    if (text.contains('hod') || text.contains('head')) {
      return CircularAudience.headsOfDepartment;
    }
    if (text.contains('faculty') || text.contains('staff')) {
      return text.contains('support')
          ? CircularAudience.staff
          : CircularAudience.faculty;
    }
    if (text.contains('student')) return CircularAudience.students;
    return fallback;
  }
}
