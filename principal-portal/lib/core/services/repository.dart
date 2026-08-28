import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Where the data on screen came from.
///
/// Only one value remains. The portal previously carried a `sample` source that
/// served built-in figures when a query failed, and the enum is kept rather than
/// dropped so `Sourced` still records provenance explicitly instead of leaving
/// it implied — a future offline or cached source would be added here.
enum DataSource {
  /// Read from Supabase.
  live,
}

/// A result plus the provenance of the data inside it.
class Sourced<T> {
  const Sourced(this.value, this.source);

  final T value;
  final DataSource source;

  bool get isLive => source == DataSource.live;

  Sourced<R> map<R>(R Function(T) transform) =>
      Sourced<R>(transform(value), source);
}

/// The result of [Repository.gatherWithReport]: the rows that came back plus
/// which named sources could not be reached.
class GatherResult<T> {
  const GatherResult(this.rows, {this.failedSources = const []});

  final List<T> rows;
  final List<String> failedSources;

  /// True when at least one source failed but others succeeded.
  bool get isPartial => failedSources.isNotEmpty && rows.isNotEmpty;

  /// True when nothing came back at all.
  bool get isEmpty => rows.isEmpty;

  /// Human-readable summary of what went wrong, safe for UI display.
  /// Never leaks schema names, SQL errors, or stack traces.
  String get partialWarning {
    if (failedSources.isEmpty) return '';
    final count = failedSources.length;
    return count == 1
        ? 'One data source could not be reached. Some records may be missing.'
        : '$count data sources could not be reached. Some records may be missing.';
  }
}

/// Base class for every data source in the portal.
///
/// Each repository declares how to fetch its live rows; [load] runs that and
/// reports provenance. There is no fallback: a screen that cannot reach the
/// database shows its error state rather than something that looks like data.
abstract class Repository {
  const Repository();

  /// Runs [fromSupabase] and reports where the result came from.
  ///
  /// There is no sample-data fallback. Quietly serving representative figures
  /// when the database is unreachable means a Principal can read a number off
  /// the screen with no way of telling it is fiction; a failed query throws and
  /// the screen says plainly that the data could not be loaded.
  ///
  /// The fallback used to be reachable through a `sample` parameter. No caller
  /// had passed one since the sample-data files were deleted, so every branch
  /// guarding it was dead, and leaving it in place meant one future caller
  /// could reintroduce fabricated institutional figures by supplying a
  /// builder. Removed rather than left as a trap.
  ///
  /// [isEmpty] is retained: callers use it to state that an empty result is
  /// meaningful for their screen. It no longer selects a fallback.
  Future<Sourced<T>> load<T>({
    required Future<T> Function() fromSupabase,
    bool Function(T)? isEmpty,
    String debugLabel = '',
  }) async {
    if (!ApiClient.isReady) {
      throw StateError(
        'No database connection${debugLabel.isEmpty ? '' : ' for $debugLabel'}. '
        'This screen has no offline data to fall back to.',
      );
    }

    try {
      return Sourced(await fromSupabase(), DataSource.live);
    } catch (error, stackTrace) {
      // Debug builds only. `debugPrint` is not compiled out of a release
      // build, and the driver error carries the schema name, the table name
      // and often the failing filter value — a map of the backend, printed to
      // the browser console of whoever has the page open.
      if (kDebugMode) {
        debugPrint(
          'Live query failed${debugLabel.isEmpty ? '' : ' ($debugLabel)'}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }

      rethrow;
    }
  }

  /// Inserts a row into a `principal` table and returns it.
  ///
  /// Writes are only ever aimed at the portal's own schema. A failure is
  /// rethrown rather than swallowed: a write that silently did nothing would
  /// leave the user believing they had saved something.
  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> values,
  ) async {
    _requireConnection('insert into $table');
    final inserted = await ApiClient.schema(
      DbSchema.principal,
    ).from(table).insert(values).select().single();
    return Map<String, dynamic>.from(inserted);
  }

  /// Updates the row with [id] in a `principal` table and returns it.
  Future<Map<String, dynamic>> updateRow(
    String table,
    String id,
    Map<String, dynamic> values,
  ) async {
    _requireConnection('update $table');
    final updated = await ApiClient.schema(
      DbSchema.principal,
    ).from(table).update(values).eq('id', id).select().single();
    return Map<String, dynamic>.from(updated);
  }

  /// Deletes the row with [id] from a `principal` table.
  void _requireConnection(String action) {
    if (!ApiClient.isReady) {
      throw StateError('Cannot $action — no database connection.');
    }
  }

  /// Runs several independent queries and keeps whatever succeeds.
  ///
  /// Some sources are unreachable — the `hod` schema is not exposed to the
  /// API, for instance — and a plain `Future.wait` would throw on the first
  /// failure and discard the rows that *did* come back. A screen fed by two
  /// tables should still show the one it can read.
  ///
  /// Returns a [GatherResult] that carries both the collected rows and the
  /// names of any sources that failed, so callers can surface partial-data
  /// warnings in the UI rather than silently dropping content.
  Future<GatherResult<T>> gatherWithReport<T>(
    Map<String, Future<List<T>> Function()> sources,
  ) async {
    final collected = <T>[];
    final failed = <String>[];

    await Future.wait(
      sources.entries.map((entry) async {
        try {
          collected.addAll(await entry.value());
        } catch (error) {
          failed.add(entry.key);
          // Debug builds only. `debugPrint` survives a release build, and
          // `entry.key` is a schema.table name — precisely what
          // [GatherResult.partialWarning] is careful never to leak.
          if (kDebugMode) {
            debugPrint('Source unavailable (${entry.key}): $error');
          }
        }
      }),
    );

    return GatherResult(collected, failedSources: failed);
  }

  /// Convenience wrapper that returns only the rows.
  ///
  /// Existing callers that do not need to surface partial-data warnings
  /// continue to work unchanged.
  Future<List<T>> gather<T>(
    Map<String, Future<List<T>> Function()> sources,
  ) async {
    final result = await gatherWithReport(sources);
    return result.rows;
  }
}

/// Helpers for reading loosely-typed PostgREST rows.
extension SupabaseRow on Map<String, dynamic> {
  String? str(String key) {
    final value = this[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String strOr(String key, String fallback) => str(key) ?? fallback;

  int intOr(String key, int fallback) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double doubleOr(String key, double fallback) {
    final value = this[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool boolOr(String key, bool fallback) {
    final value = this[key];
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    if (text == 'true' || text == 't' || text == '1') return true;
    if (text == 'false' || text == 'f' || text == '0') return false;
    return fallback;
  }

  DateTime dateOr(String key, DateTime fallback) {
    final value = this[key];
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? fallback;
  }

  /// First non-null value among [keys] — column names differ between the
  /// three portal schemas for what is conceptually the same field.
  String? firstStr(List<String> keys) {
    for (final key in keys) {
      final value = str(key);
      if (value != null) return value;
    }
    return null;
  }
}
