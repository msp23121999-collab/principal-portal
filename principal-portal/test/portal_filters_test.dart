import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/filters/portal_filters.dart';
import 'package:principal_portal/core/utils/batch_parser.dart';
import 'package:principal_portal/core/utils/program_level.dart';

/// The filter rules the whole portal depends on.
///
/// Section 15 of the requirements asks for hierarchical filters: choosing a
/// department restricts the programmes beneath it, choosing a semester
/// restricts the subjects. The failure mode is silent — a stale child
/// selection returns an empty table with no visible reason, and the screen
/// looks broken rather than filtered.
void main() {
  group('Clearing a filter', () {
    test('a set filter can be cleared back to "all"', () {
      const filters = PortalFilters(departmentCode: 'CSE', semester: 5);

      // The clear flags exist because copyWith(departmentCode: null) cannot
      // distinguish "set to all" from "leave alone".
      final cleared = filters.copyWith(clearDepartment: true);

      expect(cleared.departmentCode, isNull);
      expect(cleared.semester, 5, reason: 'other filters must survive');
    });

    test('activeCount counts only what is applied', () {
      expect(const PortalFilters().activeCount, 0);
      expect(const PortalFilters().isEmpty, isTrue);
      expect(
        const PortalFilters(
          departmentCode: 'CSE',
          yearOfStudy: 'III',
          semester: 5,
        ).activeCount,
        3,
      );
    });
  });

  group('Hierarchy', () {
    const everything = PortalFilters(
      academicYear: '2025-26',
      departmentCode: 'ECE',
      programLevel: ProgramLevel.pg,
      batch: '2022',
      yearOfStudy: 'III',
      semester: 5,
      subject: 'Electronic Circuits',
    );

    test('changing department clears everything beneath it', () {
      final narrowed = everything.narrowedFor(PortalFilterField.department);

      // All of these belong to the department that was just replaced. A batch
      // the new department never admitted is not merely wrong on screen — the
      // batch dropdown stops offering the value it is holding, and
      // DropdownButton asserts on that.
      expect(narrowed.programLevel, isNull);
      expect(narrowed.batch, isNull);
      expect(narrowed.yearOfStudy, isNull);
      expect(narrowed.semester, isNull);
      expect(narrowed.subject, isNull);

      // Academic year sits above the department, so it survives.
      expect(narrowed.academicYear, '2025-26');
      expect(narrowed.departmentCode, 'ECE');
    });

    test('changing academic year clears the whole row below it', () {
      final narrowed = everything.narrowedFor(PortalFilterField.academicYear);

      expect(narrowed.academicYear, '2025-26');
      expect(narrowed.departmentCode, isNull);
      expect(narrowed.programLevel, isNull);
      expect(narrowed.batch, isNull);
      expect(narrowed.yearOfStudy, isNull);
      expect(narrowed.semester, isNull);
      expect(narrowed.subject, isNull);
    });

    test('changing semester clears only the subject', () {
      final narrowed = everything.narrowedFor(PortalFilterField.semester);

      expect(narrowed.subject, isNull);

      // Everything above the semester is untouched.
      expect(narrowed.academicYear, '2025-26');
      expect(narrowed.departmentCode, 'ECE');
      expect(narrowed.programLevel, ProgramLevel.pg);
      expect(narrowed.batch, '2022');
      expect(narrowed.yearOfStudy, 'III');
      expect(narrowed.semester, 5);
    });

    test('changing the last filter clears nothing', () {
      expect(everything.narrowedFor(PortalFilterField.subject), everything);
    });

    test('the hierarchy matches the order the controls appear in', () {
      expect(PortalFilters.hierarchy, const [
        PortalFilterField.academicYear,
        PortalFilterField.department,
        PortalFilterField.programLevel,
        PortalFilterField.batch,
        PortalFilterField.yearOfStudy,
        PortalFilterField.semester,
        PortalFilterField.subject,
      ]);
    });
  });

  group('Programme levels', () {
    test('the four live spellings of one degree collapse to UG', () {
      // Exactly the values in student.students today. Grouping on the raw
      // text would report four undergraduate programmes instead of one.
      const recorded = [
        'B.E',
        'B.E.',
        'BE COMPUTER SCIENCE AND ENGINEERING',
        'B.Tech',
      ];

      expect(recorded.map(ProgramLevels.from).toSet(), {ProgramLevel.ug});
    });

    test('the levels are told apart', () {
      expect(ProgramLevels.from('M.E. Structural'), ProgramLevel.pg);
      expect(ProgramLevels.from('MCA'), ProgramLevel.pg);
      expect(ProgramLevels.from('Ph.D Computer Science'), ProgramLevel.phd);
      expect(ProgramLevels.from('Diploma in Mechanical'), ProgramLevel.diploma);
    });

    test('a post-graduate diploma is a diploma, not a masters', () {
      // 'Diploma' is checked before the masters rules for exactly this case;
      // reversing the order files these under PG.
      expect(
        ProgramLevels.from('Post Graduate Diploma in Management'),
        ProgramLevel.diploma,
      );
    });

    test('doctoral wins over masters in M.Phil-style values', () {
      expect(ProgramLevels.from('Ph.D / M.Phil'), ProgramLevel.phd);
    });

    test('an unreadable degree is null rather than assumed UG', () {
      // Filing an unreadable degree under UG would quietly inflate the
      // undergraduate count. A missing number beats a wrong one.
      expect(ProgramLevels.from(null), isNull);
      expect(ProgramLevels.from(''), isNull);
      expect(ProgramLevels.from('   '), isNull);
      expect(ProgramLevels.from('Certificate Course'), isNull);
    });

    test('only levels present in the data are offered', () {
      // The dropdown is built from this, so it can never offer a level that
      // returns nothing — and grows on its own as PG students are admitted.
      expect(ProgramLevels.presentIn(['B.E', 'B.E.', 'BE COMPUTER SCIENCE']), [
        ProgramLevel.ug,
      ]);

      expect(
        ProgramLevels.presentIn(['M.E', 'B.E', 'Ph.D', null, 'nonsense']),
        // Returned in enum order regardless of input order.
        [ProgramLevel.ug, ProgramLevel.pg, ProgramLevel.phd],
      );

      expect(ProgramLevels.presentIn([]), isEmpty);
    });
  });

  group('Batch from a register number', () {
    test('both live register formats yield the admission year', () {
      // Exactly the two shapes in the database today.
      expect(BatchParser.startYearFrom('22CSE001'), 2022);
      expect(BatchParser.startYearFrom('2022IOT001'), 2022);
    });

    test('a sequential number with no year in it yields nothing', () {
      // '731521101' is a real register number on the roll. Reading its first
      // two digits as a year would file the student in the batch of 2073.
      expect(BatchParser.startYearFrom('731521101'), isNull);
      expect(BatchParser.startYearFrom(''), isNull);
      expect(BatchParser.startYearFrom(null), isNull);
    });

    test('the two-digit rule needs letters after it', () {
      // The letters are what separate '22CSE001' from '731521101'.
      expect(BatchParser.startYearFrom('22CSE001'), 2022);
      expect(BatchParser.startYearFrom('2215211'), isNull);
    });

    test('a start year becomes the range a Principal reads', () {
      expect(BatchParser.rangeFromStartYear(2022), '2022–2026');
      expect(BatchParser.rangeFromStartYear(2022, years: 2), '2022–2024');
      // Null in, null out: the caller shows an em dash rather than a
      // fabricated range.
      expect(BatchParser.rangeFromStartYear(null), isNull);
    });

    test('a stored batch value is read back for comparison', () {
      // student.students stores '2022'; placements derive 2022 from the roll
      // number. Both have to land on the same integer or the batch filter
      // silently matches nothing.
      expect(BatchParser.startYearFromBatch('2022'), 2022);
      expect(BatchParser.startYearFromBatch('2022–2026'), 2022);
      expect(BatchParser.startYearFromBatch(''), isNull);
    });
  });
}
