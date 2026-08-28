import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/services/api_client.dart';
import 'package:principal_portal/core/services/repository.dart';
import 'package:principal_portal/core/utils/department_normalizer.dart';

/// Guards the live-data layer: department names must collapse to one code,
/// every screen must survive a missing or failing backend, and no lookup may
/// throw on an unrecognised department.
void main() {
  group('DepartmentNormalizer', () {
    test('the five recorded spellings collapse to two departments', () {
      // Exactly the values the database report found in the live tables.
      const recorded = [
        'CSE',
        'Computer Science and Engineering',
        'Computer Science & Engineering',
        'Internet of Things (IOT)',
        'Internet of Things (IoT)',
      ];

      final codes = recorded.map(DepartmentNormalizer.codeFor).toSet();

      expect(
        codes,
        {'CSE', 'IOT'},
        reason:
            'Counting raw department text would report four Computer Science '
            'departments instead of one and corrupt every institution total.',
      );
    });

    test('case and spacing do not create new departments', () {
      expect(DepartmentNormalizer.codeFor('cse'), 'CSE');
      expect(DepartmentNormalizer.codeFor('  CSE  '), 'CSE');
      expect(DepartmentNormalizer.codeFor('Mechanical Engineering'), 'MECH');
      expect(DepartmentNormalizer.codeFor('mech'), 'MECH');
    });

    test('blank and null values are kept as UNKNOWN, not dropped', () {
      // Rows with no department must still appear in totals, or the
      // institution headcount silently under-reports.
      expect(DepartmentNormalizer.codeFor(null), 'UNKNOWN');
      expect(DepartmentNormalizer.codeFor(''), 'UNKNOWN');
      expect(DepartmentNormalizer.codeFor('   '), 'UNKNOWN');
    });

    test('an unrecognised department survives rather than being discarded', () {
      expect(
        DepartmentNormalizer.codeFor('Marine Engineering'),
        'MARINE ENGINEERING',
      );
    });

    test('grouping keys on the normalised code', () {
      final rows = [
        ('a', 'CSE'),
        ('b', 'Computer Science and Engineering'),
        ('c', 'Internet of Things (IoT)'),
      ];

      final grouped = DepartmentNormalizer.groupByDepartment(
        rows,
        (row) => row.$2,
      );

      expect(grouped['CSE']!.length, 2);
      expect(grouped['IOT']!.length, 1);
    });
  });

  group('Department codes match the database', () {
    test('Science & Humanities normalises to the code the database uses', () {
      // `principal.departments` stores this department as 'SCI'. When the
      // normaliser emitted 'S&H' instead, any figure grouped by code missed it
      // entirely — the department vanished from cross-source rollups.
      expect(DepartmentNormalizer.codeFor('Science and Humanities'), 'SCI');
      expect(DepartmentNormalizer.codeFor('Science & Humanities'), 'SCI');
      expect(DepartmentNormalizer.codeFor('S&H'), 'SCI');
      expect(DepartmentNormalizer.codeFor('SCI'), 'SCI');
    });

    test('every canonical code has a display name', () {
      // A code with no name would render as the raw code on screen.
      for (final code in DepartmentNormalizer.canonicalNames.keys) {
        expect(DepartmentNormalizer.displayName(code), isNot(code));
      }
    });
  });

  group('Repository with no backend', () {
    test('throws rather than inventing figures', () async {
      // Every screen now reads the database and nothing else. Quietly serving
      // representative numbers when the database is unreachable would let a
      // Principal read a figure off the screen with no way of telling it is
      // fiction, so a failed load must surface as an error state instead.
      expect(ApiClient.isReady, isFalse);

      await expectLater(
        const _TestRepository().loadNumbers(
          fromSupabase: () async => [1, 2, 3],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SupabaseRow parsing', () {
    test('reads values regardless of the column name used', () {
      final row = <String, dynamic>{'full_name': 'Dr. A. Rajendran'};
      expect(row.firstStr(['name', 'full_name']), 'Dr. A. Rajendran');
      expect(row.firstStr(['missing', 'absent']), isNull);
    });

    test('coerces loose types and falls back safely', () {
      final row = <String, dynamic>{
        'count': '12',
        'score': '8.4',
        'flag': 'true',
        'blank': '   ',
      };

      expect(row.intOr('count', 0), 12);
      expect(row.doubleOr('score', 0), 8.4);
      expect(row.boolOr('flag', false), isTrue);
      expect(row.str('blank'), isNull);
      expect(row.intOr('missing', 7), 7);
    });

    test('an unparsable date falls back rather than throwing', () {
      final row = <String, dynamic>{'created_at': 'not a date'};
      final fallback = DateTime(2026, 1, 1);
      expect(row.dateOr('created_at', fallback), fallback);
    });
  });
}

/// Minimal concrete repository so the protected [Repository.load] contract
/// can be exercised directly.
class _TestRepository extends Repository {
  const _TestRepository();

  Future<Sourced<List<int>>> loadNumbers({
    required Future<List<int>> Function() fromSupabase,
  }) {
    return load<List<int>>(fromSupabase: fromSupabase);
  }
}
