import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/services/export/csv_serializer.dart';
import 'package:principal_portal/core/services/reference_sequence.dart';
import 'package:principal_portal/core/services/storage/read_state_store.dart';


/// Regression cover for the security controls added during the 2026-08 audit.
///
/// Each of these replaced a real defect found against the live database or the
/// running app. None of them had a test, which meant any of them could be
/// removed later and nothing would notice — the failure mode is silent, and in
/// two cases the consequence is data leaving the institution.
void main() {
  group('CSV export cannot be turned into a formula', () {
    // A circular titled `=HYPERLINK(...)` stored in the database used to
    // execute when the Principal opened the export in Excel.
    test('a cell opening with a formula character is neutralised', () {
      for (final payload in const [
        '=HYPERLINK("http://evil.test","click")',
        '+1+1',
        '@SUM(A1:A9)',
        '=cmd|\' /c calc\'!A1',
      ]) {
        final escaped = CsvSerializer.escapeField(payload);
        expect(
          escaped.startsWith('"\'') || escaped.startsWith("'"),
          isTrue,
          reason: '"$payload" must not reach a spreadsheet as a formula.',
        );
      }
    });

    test('tab and carriage return are treated as formula leads', () {
      // Excel strips these and evaluates whatever follows.
      expect(CsvSerializer.neutraliseFormula('\t=1+1'), startsWith("'"));
      expect(CsvSerializer.neutraliseFormula('\r=1+1'), startsWith("'"));
    });

    test('negative numbers are left alone so exports still sum', () {
      // The portal exports deficits and negative surpluses. Quoting these into
      // text would break every sum built on top of the export.
      for (final number in const ['-1234', '-0.5', '-12.75', '-1e3']) {
        expect(
          CsvSerializer.neutraliseFormula(number),
          number,
          reason: '$number is a figure, not a formula.',
        );
      }
    });

    test('ordinary values are untouched and separators still escape', () {
      expect(
        CsvSerializer.escapeField('Dr. S. Venkataraman'),
        'Dr. S. Venkataraman',
      );
      expect(CsvSerializer.escapeField('CSE, ECE'), '"CSE, ECE"');
      expect(CsvSerializer.escapeField('He said "no"'), '"He said ""no"""');
      expect(CsvSerializer.escapeField(''), '');
    });

    test('a full document carries the BOM and one line per row', () {
      final csv = CsvSerializer.toCsv(
        headers: const ['Department', 'Outstanding'],
        rows: const [
          ['CSE', -1200],
          ['=EVIL()', 0],
        ],
      );

      expect(csv.startsWith(CsvSerializer.utf8Bom), isTrue);
      expect(csv, contains('CSE,-1200'));
      expect(csv, contains("'=EVIL()"));
      expect(csv.trim().split('\n').length, 3);
    });
  });

  group('Notification read state is scoped to the signed-in user', () {
    // The key was global and survived sign-out, so on a shared browser the next
    // Principal inherited the previous one's read state and the unread badge
    // undercounted.
    test('two users never share a key', () {
      final a = ReadStateStore.keyFor('11111111-1111-1111-1111-111111111111');
      final b = ReadStateStore.keyFor('22222222-2222-2222-2222-222222222222');

      expect(a, isNot(equals(b)));
      expect(a, contains('11111111-1111-1111-1111-111111111111'));
    });

    test('the same user is stable across calls', () {
      expect(ReadStateStore.keyFor('abc'), ReadStateStore.keyFor('abc'));
    });

    test(
      'an absent identity falls back to the unscoped key, not to someone else',
      () {
        // A portal running without a backend has no identity to scope to.
        expect(ReadStateStore.keyFor(null), ReadStateStore.keyFor(''));
        expect(ReadStateStore.keyFor(null), isNot(contains(':')));
      },
    );
  });

  group('Institutional reference numbers survive a collision', () {
    // `circulars.reference` is uniquely indexed, so two simultaneous publishes
    // do not duplicate — the second one fails and the circular is lost unless
    // it is retried.
    Exception collision() => Exception(
      'duplicate key value violates unique constraint on reference (23505)',
    );

    test('a collision is retried with a freshly computed reference', () async {
      var issued = 0;
      final attempted = <String>[];

      await ReferenceSequence.insertWithRetry(
        nextReference: () async {
          issued++;
          return 'KSRCE/PRIN/2026/${issued.toString().padLeft(3, '0')}';
        },
        insert: (reference) async {
          attempted.add(reference);
          // The first two references are already taken.
          if (attempted.length < 3) throw collision();
        },
      );

      expect(attempted, [
        'KSRCE/PRIN/2026/001',
        'KSRCE/PRIN/2026/002',
        'KSRCE/PRIN/2026/003',
      ]);
    });

    test('it gives up rather than looping forever', () async {
      var attempts = 0;

      await expectLater(
        ReferenceSequence.insertWithRetry(
          nextReference: () async => 'KSRCE/PRIN/2026/001',
          insert: (_) async {
            attempts++;
            throw collision();
          },
          maxAttempts: 3,
        ),
        throwsA(isA<Exception>()),
      );

      expect(attempts, 3);
    });

    test(
      'a non-collision error is rethrown immediately, never retried',
      () async {
        // A permission failure must surface at once. Retrying it would turn one
        // RLS rejection into a burst of identical rejected writes.
        var attempts = 0;

        await expectLater(
          ReferenceSequence.insertWithRetry(
            nextReference: () async => 'KSRCE/PRIN/2026/001',
            insert: (_) async {
              attempts++;
              throw Exception(
                'new row violates row-level security policy (42501)',
              );
            },
          ),
          throwsA(isA<Exception>()),
        );

        expect(attempts, 1, reason: 'An RLS rejection must not be retried.');
      },
    );

    test('a first-time success does not retry', () async {
      var attempts = 0;

      await ReferenceSequence.insertWithRetry(
        nextReference: () async => 'KSRCE/PRIN/2026/001',
        insert: (_) async => attempts++,
      );

      expect(attempts, 1);
    });
  });
}
