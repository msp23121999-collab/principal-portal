

/// Inserts a row whose institutional reference number has to be unique.
///
/// References like `KSRCE/PRIN/2026/004` are produced by reading the highest
/// one already issued and adding one. Two people publishing at the same moment
/// read the same number, and `principal.circulars.reference` carries a unique
/// index — so the second insert fails rather than silently duplicating. That is
/// the right behaviour from the database, and the wrong experience for whoever
/// was second: their circular simply did not save.
///
/// Retrying re-reads the sequence, so the loser of the race takes the next
/// number instead of losing the write.
///
/// The proper fix is a database sequence or an insert-returning RPC, so the
/// number is allocated atomically rather than read-then-written. That is a
/// schema change and is recorded as a remaining dependency; this closes the
/// window from the client without one.
class ReferenceSequence {
  ReferenceSequence._();

  /// PostgreSQL's unique-violation SQLSTATE.
  static const String uniqueViolation = '23505';

  /// Calls [insert] with a freshly computed reference, retrying on a unique
  /// violation up to [maxAttempts] times.
  ///
  /// Any other error is rethrown immediately — a permission failure or a
  /// malformed row must not be retried into a loop.
  static Future<void> insertWithRetry({
    required Future<String> Function() nextReference,
    required Future<void> Function(String reference) insert,
    int maxAttempts = 4,
  }) async {
    for (var attempt = 1; ; attempt++) {
      final reference = await nextReference();
      try {
        await insert(reference);
        return;
      } on Exception catch (error) {
        final errorMessage = error.toString().toLowerCase();
        final isCollision = errorMessage.contains('23505') ||
            (errorMessage.contains('duplicate key') &&
                errorMessage.contains('reference'));

        if (!isCollision || attempt >= maxAttempts) rethrow;
        // Fall through and try again with a recomputed reference.
      }
    }
  }
}
