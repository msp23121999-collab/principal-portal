import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards a whole class of defect that cannot be caught any other way.
///
/// `postgrest`'s `.order()` defaults to **descending**. Every chart in this
/// portal was once drawn backwards because 24 call sites relied on that
/// default: admissions genuinely rose from 2,650 to 3,410 and the chart showed
/// them falling.
///
/// Those 24 were fixed by hand. One survived — `academic_repository`'s shared
/// `_simpleList` helper, whose column name is a variable, so a reader scanning
/// for a literal column name missed it. It reversed `sgpa_bands`,
/// `grade_slices` and `yearly_pass_rates`, which swapped the "distinction" and
/// "needs support" cards on the SGPA tab: 520 was reported as distinctions and
/// 486 as needing support, when the truth was the other way round.
///
/// A test that asserts a chart's contents cannot catch this — it needs a live
/// database, and the bug is invisible unless you know the intended order. So
/// this reads the source instead and requires every `.order(` to state its
/// direction. It is unusual to test source text, and it is the right tool here:
/// the rule is "never rely on this default", and that is a property of the
/// code, not of any one query's result.
void main() {
  group('PostgREST query safety', () {
    test('every .order() states its direction explicitly', () {
      final offenders = <String>[];

      for (final file in _dartFilesUnder('lib')) {
        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (!line.contains('.order(')) continue;
          // Comments and doc comments discuss `.order()` without calling it —
          // including the comment on the very call this test was written for.
          if (line.startsWith('//') || line.startsWith('///')) continue;

          // The call may wrap, so read the statement, not the line. Joining
          // the next few lines is enough: no `.order()` in this codebase
          // spans more than a handful.
          final statement = lines.skip(i).take(4).join(' ');
          if (statement.contains('ascending:')) continue;

          offenders.add('${file.path}:${i + 1}  $line');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'postgrest .order() defaults to DESCENDING. Every call must say '
            '`ascending: true` or `ascending: false` so the reader can see '
            'which way a chart will be drawn:\n${offenders.join('\n')}',
      );
    });
  });
}

Iterable<File> _dartFilesUnder(String directory) sync* {
  for (final entity in Directory(directory).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
