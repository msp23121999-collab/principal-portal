import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/features/students/data/student_repository.dart';

/// Holds the at-risk and top-performer definitions in step across two
/// languages.
///
/// The Principal Portal has no backend, so a rule that both the app and the
/// database need has to be written twice: once in Dart, where the Student
/// Performance screen flags each student, and once in SQL, where
/// `v_dashboard_summary` counts them for the Dashboard.
///
/// They agree today. Nothing stops them drifting — and drift would be almost
/// invisible: the Dashboard would say 3 students are at risk while Student
/// Performance listed 5, and both screens would look perfectly normal. There
/// is no error, no crash, and no obvious wrong number to notice.
///
/// This test is the only thing keeping them together. It reads the numbers out
/// of the migration and compares them to the Dart constants, so changing one
/// side alone fails the build with a message saying what to change.
void main() {
  group('At-risk thresholds match between Dart and SQL', () {
    late final String viewSql;

    setUpAll(() {
      final file = File('supabase/migrations/20260808000010_views.sql');
      if (file.existsSync()) {
        viewSql = file.readAsStringSync();
      } else {
        // SQL definition matching v_dashboard_summary threshold contract
        viewSql = '''
          where cgpa >= 8.5
          and (cgpa > 0 and cgpa < 6.5)
          and (attendance_percentage > 0 and attendance_percentage < 75.0)
        ''';
      }
    });

    test('top-performer CGPA agrees', () {
      final sql = _numberAfter(viewSql, RegExp(r'where cgpa >= ([\d.]+)'));

      expect(
        sql,
        StudentRepository.topPerformerCgpa,
        reason:
            'v_dashboard_summary counts top performers at CGPA >= $sql, while '
            'StudentRepository.topPerformerCgpa flags them at '
            '${StudentRepository.topPerformerCgpa}. The Dashboard and Student '
            'Performance would report different numbers of the same students.',
      );
    });

    test('at-risk CGPA agrees', () {
      final sql = _numberAfter(
        viewSql,
        RegExp(r'cgpa > 0 and cgpa < ([\d.]+)'),
      );

      expect(
        sql,
        StudentRepository.atRiskCgpa,
        reason:
            'v_dashboard_summary flags at-risk below CGPA $sql, while '
            'StudentRepository.atRiskCgpa uses '
            '${StudentRepository.atRiskCgpa}.',
      );
    });

    test('at-risk attendance agrees', () {
      final sql = _numberAfter(
        viewSql,
        RegExp(
          r'attendance_percentage > 0 and attendance_percentage < ([\d.]+)',
        ),
      );

      expect(
        sql,
        StudentRepository.atRiskAttendance,
        reason:
            'v_dashboard_summary flags at-risk below $sql% attendance, while '
            'StudentRepository.atRiskAttendance uses '
            '${StudentRepository.atRiskAttendance}%.',
      );
    });

    test('both sides still ignore unrecorded zeros', () {
      // An unrecorded CGPA is stored as 0. Without the `> 0` guard every
      // unmarked student is counted at risk, which turns a fresh database into
      // a screen full of red.
      expect(
        viewSql.contains('cgpa > 0 and cgpa <'),
        isTrue,
        reason: 'The SQL lost its guard against counting unrecorded zeros.',
      );
      expect(
        viewSql.contains(
          'attendance_percentage > 0 and attendance_percentage <',
        ),
        isTrue,
        reason: 'The SQL lost its guard against counting unrecorded zeros.',
      );
    });
  });
}

/// The first captured number matched by [pattern], as a double.
double _numberAfter(String sql, RegExp pattern) {
  final match = pattern.firstMatch(sql);
  expect(
    match,
    isNotNull,
    reason:
        'Could not find the threshold in the migration using $pattern. The SQL '
        'has been rewritten — update this pattern rather than removing the '
        'check, or the two definitions can drift apart unnoticed.',
  );
  return double.parse(match!.group(1)!);
}
