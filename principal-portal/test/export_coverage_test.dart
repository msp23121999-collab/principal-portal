import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against an Export button that shows a message and produces nothing.
///
/// Twelve controls in this portal offered a download. Three wrote a file. The
/// other nine showed a snackbar — "Accreditation status report queued for
/// export." was the entire Accreditation export — and a Principal pressing
/// Export before a board meeting was left with a toast.
///
/// A widget test cannot prove a browser download happened: the CSV writer uses
/// `dart:js_interop`, which does not exist on the Dart VM the tests run on, so
/// a stub stands in there. What can be proved is that every file offering an
/// export reaches an exporter, and that none of the old stub wording has crept
/// back.
void main() {
  final exportingFiles = [
    for (final file in _dartFilesUnder('lib'))
      if (_offersExport.hasMatch(file.readAsStringSync())) file,
  ];

  group('Export controls', () {
    test('the sweep finds the export controls at all', () {
      // Without this the two tests below could pass by matching nothing.
      expect(
        exportingFiles.length,
        greaterThanOrEqualTo(12),
        reason:
            'Expected the known export-bearing screens to be found. If this '
            'drops, the pattern below has stopped matching and the real '
            'checks are no longer running.',
      );
    });

    test('every file offering an export reaches an exporter', () {
      final offenders = <String>[];

      for (final file in exportingFiles) {
        final source = file.readAsStringSync();
        if (_importsExporter(source)) continue;
        // A disabled control is honest — it promises nothing. The Repository's
        // download icon is one: there is no file to fetch and it says so.
        if (source.contains('onPressed: null')) continue;
        // A screen may hand the work to a helper instead of importing the
        // exporter itself — Institution Overview delegates to
        // `InstitutionYearControls.export`, which is where the real
        // `TableExport.run` call lives. Follow one hop before calling it dead:
        // the button still produces a file, which is what this guards.
        if (_delegatesToExporter(source)) continue;

        offenders.add(file.path);
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These label a control as an export but pull in no exporter:\n'
            '${offenders.join('\n')}',
      );
    });

    test('none of the old stub wording survives', () {
      final offenders = <String>[];

      // The exact phrases the nine dead buttons used.
      const stubPhrases = [
        'queued for export',
        'export simulated',
        'Export simulated',
        'queued for download',
        'report queued',
        'no backend yet',
      ];

      for (final file in _dartFilesUnder('lib')) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Comments explain why the wording was removed; they are not the bug.
          if (line.trimLeft().startsWith('//')) continue;
          for (final phrase in stubPhrases) {
            if (line.contains(phrase)) {
              offenders.add('${file.path}:${i + 1}  ${line.trim()}');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'This wording tells the user something was exported when nothing '
            'was:\n${offenders.join('\n')}',
      );
    });
  });
}

/// A control labelled as producing a file.
final RegExp _offersExport = RegExp(
  r"(label|actionLabel|secondaryActionLabel|tooltip): '[^']*"
  r"(Export|Download|Generate Report)[^']*'",
);

/// True when the source pulls in one of the two real exporters.
bool _importsExporter(String source) =>
    source.contains('csv_export.dart') || source.contains('table_export.dart');

/// A call like `SomeWidget.export(` or `SomeService.exportRows(`.
final RegExp _exportDelegate = RegExp(r'\b([A-Z]\w+)\.export\w*\(');

/// True when the source hands its export to a type whose own file reaches an
/// exporter.
///
/// Only one hop is followed, and the target has to be a real type defined
/// under `lib`. A screen that calls `Something.export(...)` where nothing by
/// that name exists, or where it exists but writes no file, is still reported.
bool _delegatesToExporter(String source) {
  for (final match in _exportDelegate.allMatches(source)) {
    final typeName = match.group(1);
    if (typeName == null) continue;

    for (final file in _dartFilesUnder('lib')) {
      final target = file.readAsStringSync();
      if (!target.contains('class $typeName ')) continue;
      if (_importsExporter(target)) return true;
    }
  }
  return false;
}

Iterable<File> _dartFilesUnder(String directory) sync* {
  for (final entity in Directory(directory).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
