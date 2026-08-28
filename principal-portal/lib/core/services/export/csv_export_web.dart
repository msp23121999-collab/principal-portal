import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../utils/date_formatter.dart';
import 'csv_serializer.dart';

/// Turns a table on screen into a file the Principal can actually keep.
///
/// Every "Export Report" button in the portal used to show a snackbar and
/// produce nothing — a Principal clicking Export before a board meeting was
/// left with a toast. This writes a real CSV and hands it to the browser.
///
/// CSV rather than PDF deliberately: the figures here are tabular and end up
/// in a spreadsheet nine times out of ten, and a CSV is honest about being
/// data rather than dressing it as a typeset report the portal cannot
/// actually produce.
class CsvExportImpl {
  CsvExportImpl._();

  /// Writes [rows] under [headers] and starts the download.
  ///
  /// [fileName] is stamped with the date, so a Principal exporting the same
  /// table twice in a week ends up with two files rather than one overwriting
  /// the other in their downloads folder.
  static void download({
    required String fileName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final content = CsvSerializer.toCsv(headers: headers, rows: rows);
    final stamped =
        '${fileName}_${DateFormatter.fileStamp(DateTime.now())}.csv';

    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = stamped;
    anchor.click();

    // The object URL pins the blob in memory until it is released; a Principal
    // exporting repeatedly through a long session would otherwise accumulate
    // every file they had ever downloaded.
    web.URL.revokeObjectURL(url);
  }
}
