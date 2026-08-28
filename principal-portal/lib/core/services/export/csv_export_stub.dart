/// Non-browser stand-in for [CsvExportImpl].
///
/// The portal only ever runs on the web, but the widget tests run on the Dart
/// VM, where `dart:js_interop` does not exist. Importing the browser
/// implementation unconditionally broke every test that touched a screen with
/// an export button. The conditional import in `csv_export.dart` picks this
/// instead when there is no browser to hand.
class CsvExportImpl {
  CsvExportImpl._();

  /// Does nothing off the web. A test asserting on an export should assert on
  /// the rows handed to it, not on a file the VM cannot write.
  static void download({
    required String fileName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {}
}
