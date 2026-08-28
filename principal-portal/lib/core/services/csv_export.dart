import 'export/csv_export_stub.dart'
    if (dart.library.js_interop) 'export/csv_export_web.dart';

/// Turns a table on screen into a file the Principal can actually keep.
///
/// Every "Export Report" button in the portal used to show a snackbar and
/// produce nothing — a Principal clicking Export before a board meeting was
/// left with a toast. This writes a real CSV and hands it to the browser.
///
/// CSV rather than PDF deliberately: these figures are tabular and end up in a
/// spreadsheet nine times out of ten, and a CSV is honest about being data
/// rather than dressing it as a typeset report the portal cannot produce.
///
/// The implementation is chosen at compile time. The browser version uses
/// `dart:js_interop`, which does not exist on the Dart VM the widget tests run
/// on, so a stub stands in there.
class CsvExport {
  CsvExport._();

  /// Writes [rows] under [headers] and starts the download.
  ///
  /// [fileName] is stamped with the date, so exporting the same table twice in
  /// a week leaves two files rather than one silently replacing the other.
  static void download({
    required String fileName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) =>
      CsvExportImpl.download(fileName: fileName, headers: headers, rows: rows);
}
