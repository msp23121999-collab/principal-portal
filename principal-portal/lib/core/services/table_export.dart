import 'package:flutter/material.dart';

import 'csv_export.dart';

/// One way to turn a table on screen into a file, used by every Export button.
///
/// Before this, three screens wrote a real CSV and nine showed a message and
/// produced nothing — "Accreditation status report queued for export." was the
/// whole of the Accreditation export. A Principal pressing Export before a
/// board meeting was left with a toast.
///
/// Wrapping the empty check, the download and the confirmation in one place
/// means a new export is a column list and nothing else, and that the wording a
/// Principal sees is identical everywhere.
class TableExport {
  TableExport._();

  /// Writes [rows] to a CSV and tells the user what happened.
  ///
  /// [noun] names what was exported, singular — 'faculty member', 'offer',
  /// 'request'. It appears in both messages, so it should read naturally after
  /// a number.
  ///
  /// Nothing is written when [rows] is empty. A file with only headers looks
  /// like a failed export, and the usual reason for an empty table is a filter
  /// the Principal can simply widen — so say that instead.
  static void run(
    BuildContext context, {
    required String fileName,
    required String noun,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    if (rows.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Nothing to export for this selection. Try widening the filters.',
          ),
        ),
      );
      return;
    }

    CsvExport.download(fileName: fileName, headers: headers, rows: rows);

    final plural = rows.length == 1 ? noun : '${noun}s';
    messenger.showSnackBar(
      SnackBar(content: Text('Exported ${rows.length} $plural.')),
    );
  }
}
