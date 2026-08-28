import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/utils/number_formatter.dart';
import 'package:principal_portal/features/faculty/models/faculty.dart';
import 'package:principal_portal/features/faculty/models/faculty_detail.dart';

/// Guards the rule that the portal must never show a number nobody entered.
///
/// `FacultyDetail` used to carry a `forFaculty` factory that built a whole
/// record out of `id.hashCode` — weekly hours, subjects handled, mentees, a
/// qualification guessed from job title, and an email address manufactured
/// from the person's name. Four real, named members of staff were being shown
/// those figures, because `faculty.faculties` has 16 rows and
/// `principal.faculty_details` has 12.
///
/// It is an easy thing to reintroduce: it looks like a helpful default and it
/// makes an empty screen look finished. These tests make it fail loudly.
void main() {
  group('FacultyDetail.fromRosterRow', () {
    test('carries the roster values through untouched', () {
      const faculty = Faculty(
        id: 'EMP_CSE_008',
        name: 'Prof. Muththukumaran',
        designation: FacultyDesignation.professor,
        departmentId: 'CSE',
        experienceYears: 12,
        attendancePercent: 0,
        researchPapersCount: 4,
        performanceScore: 0,
        qualification: 'M.E., Ph.D.',
        weeklyWorkloadHours: 18,
      );

      final detail = FacultyDetail.fromRosterRow(faculty);

      expect(detail.qualification, 'M.E., Ph.D.');
      expect(detail.weeklyTeachingHours, 18);
    });

    test('leaves everything unrecorded as null, never zero', () {
      const faculty = Faculty(
        id: 'EMP_CSE_009',
        name: 'Dr. S. Karthi',
        designation: FacultyDesignation.assistantProfessor,
        departmentId: 'CSE',
        experienceYears: 4,
        attendancePercent: 0,
        researchPapersCount: 0,
        performanceScore: 0,
      );

      final detail = FacultyDetail.fromRosterRow(faculty);

      expect(
        [
          detail.mentees,
          detail.appraisalScore,
          detail.feedbackScore,
          detail.fundedProjects,
          detail.subjectsHandled,
          detail.weeklyTeachingHours,
          detail.qualification,
          detail.email,
        ],
        everyElement(isNull),
        reason:
            'A zero here would read as "0 mentees" and "appraisal score 0", '
            'both of which are claims. Null renders as an em dash, which is '
            'the truth: not recorded.',
      );

      expect(
        detail.achievements,
        isEmpty,
        reason:
            'Recognitions were once awarded by a threshold in code — anyone '
            'scoring 90+ was given a "Best Faculty Award, 2024-25" nobody '
            'issued.',
      );
    });

    test('an unknown workload is not reported as within the norm', () {
      const faculty = Faculty(
        id: 'EMP_CSE_011',
        name: 'Prof. Ramya',
        designation: FacultyDesignation.assistantProfessor,
        departmentId: 'CSE',
        experienceYears: 6,
        attendancePercent: 0,
        researchPapersCount: 0,
        performanceScore: 0,
      );

      expect(FacultyDetail.fromRosterRow(faculty).isOverloaded, isFalse);
      expect(
        const FacultyDetail(
          facultyId: 'x',
          weeklyTeachingHours: 24,
        ).isOverloaded,
        isTrue,
      );
      expect(
        const FacultyDetail(
          facultyId: 'x',
          weeklyTeachingHours: 18,
        ).isOverloaded,
        isFalse,
        reason: 'The norm is inclusive: 18 hours is at the norm, not over it.',
      );
    });
  });

  group('NumberFormatter.orDash', () {
    test('renders an em dash for null and the value otherwise', () {
      expect(NumberFormatter.orDash(null), NumberFormatter.unrecorded);
      expect(NumberFormatter.orDash(18), '18');
      expect(NumberFormatter.orDash(18, (h) => '$h hrs'), '18 hrs');
      expect(
        NumberFormatter.orDash<double>(null, (h) => '$h hrs'),
        NumberFormatter.unrecorded,
      );
    });

    test('zero is a real value and is shown, not dashed', () {
      expect(
        NumberFormatter.orDash(0),
        '0',
        reason:
            'A recorded zero is a fact. Only an absent value gets the dash — '
            'collapsing the two is exactly the confusion this guards against.',
      );
    });
  });

  group('No fabricating factory returns', () {
    test('nothing in lib/ derives a displayed value from hashCode', () {
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) continue;
          if (!line.contains('hashCode')) continue;
          // A model's own `get hashCode` override is the legitimate use.
          if (line.contains('int get hashCode')) continue;
          if (line.contains('Object.hash')) continue;

          offenders.add('${entity.path}:${i + 1}  $line');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'hashCode is for equality, never for generating a figure to show '
            'a Principal. Faculty workload, subjects handled and mentee counts '
            'were all produced this way:\n${offenders.join('\n')}',
      );
    });
  });
}
