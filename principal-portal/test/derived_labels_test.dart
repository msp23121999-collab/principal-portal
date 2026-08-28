import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/utils/date_formatter.dart';

/// Guards captions against stating a year the data does not have.
///
/// Four headings named a period in code — "End-semester examinations, April -
/// May 2025", "Academic Calendar 2025-26", "Campus visits scheduled for the
/// 2025-26 placement season", and a chart legend fixed to "2024 - 2025" and
/// "2023 - 2024". Each was true when written and wrong the moment the next
/// session, season or semester was published. The legend was the worst of them:
/// it named two academic years beside bars drawn from whichever two semesters
/// happened to be most recent.
void main() {
  group('DateFormatter.monthRange', () {
    test('a single month reads as one month', () {
      expect(
        DateFormatter.monthRange([DateTime(2025, 4, 2), DateTime(2025, 4, 28)]),
        'April 2025',
      );
    });

    test('months within one year state the year once', () {
      expect(
        DateFormatter.monthRange([DateTime(2025, 4, 2), DateTime(2025, 5, 30)]),
        'April – May 2025',
      );
    });

    test('a range crossing new year states both years', () {
      expect(
        DateFormatter.monthRange([
          DateTime(2025, 11, 3),
          DateTime(2026, 2, 14),
        ]),
        'November 2025 – February 2026',
      );
    });

    test('order does not matter', () {
      expect(
        DateFormatter.monthRange([DateTime(2025, 5, 30), DateTime(2025, 4, 2)]),
        'April – May 2025',
      );
    });

    test('nothing to describe returns null, not a made-up period', () {
      expect(
        DateFormatter.monthRange(const []),
        isNull,
        reason:
            'The caller leaves the caption off. Naming a period for an empty '
            'table is how these headings went wrong in the first place.',
      );
    });
  });

  group('A trend badge describes its own card', () {
    test('Research cards carry no trend from a different dataset', () {
      final source = File(
        'lib/features/research/widgets/tabs/research_overview_tab.dart',
      ).readAsStringSync();

      expect(
        source.contains('trendValue:'),
        isFalse,
        reason:
            'The Publications and Patents cards count '
            '`faculty.research_publications` and `faculty.patents` (8 and 0). '
            'The only year-on-year history is `research_year_output`, a '
            'separate series running 42-94 and 3-14. A trend taken from the '
            'second and shown beside a value from the first reads "0 patents '
            'filed, up 27.3%" — which is what happened when the hardcoded '
            '"26.3% vs 2023-24" was replaced with a computed figure from the '
            'wrong table. There is no prior-year figure for these counts, so '
            'there is no trend to show.',
      );
    });
  });

  group('No caption states a year in code', () {
    test('no widget hardcodes an academic year or session', () {
      final offenders = <String>[];

      // A four-digit year inside a user-facing string: '2025-26',
      // '2024 - 2025', 'April - May 2025'.
      final hardcodedYear = RegExp(
        r"'[^']*\b20\d{2}\s*[-–]\s*(20)?\d{2}\b[^']*'",
      );

      for (final file in _dartFilesUnder('lib')) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Comments record what the old wording was; they are not the bug.
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
          if (!hardcodedYear.hasMatch(line)) continue;

          offenders.add('${file.path}:${i + 1}  ${line.trim()}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Read the period from the rows on screen instead — see '
            'DateFormatter.monthRange:\n${offenders.join('\n')}',
      );
    });
  });
}

Iterable<File> _dartFilesUnder(String directory) sync* {
  for (final entity in Directory(directory).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
