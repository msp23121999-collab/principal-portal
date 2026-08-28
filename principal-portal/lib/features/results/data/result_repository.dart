import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/semester_result.dart';

/// Reads Result Analytics from `principal`.
///
/// A semester's result is two tables: the headline pass percentage in
/// `semester_results`, and the per-department breakdown in
/// `semester_result_departments`. The Dart model nests the breakdown inside
/// the result, which a single embedded select reproduces in one round trip.
class ResultRepository extends Repository {
  const ResultRepository();

  /// The semesters that have published results, most recent first.
  ///
  /// Read from the database rather than hardcoded, so a newly published
  /// semester appears in the dropdown without a code change.
  Future<Sourced<List<String>>> fetchSemesters() {
    return load<List<String>>(
      debugLabel: 'principal.semester_results (labels)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('semester_results')
            .select('semester_label, published_on')
            .order('published_on', ascending: false);

        return [
          for (final raw in rows)
            Map<String, dynamic>.from(raw).strOr('semester_label', ''),
        ]..removeWhere((label) => label.isEmpty);
      },
    );
  }

  Future<Sourced<SemesterResult>> fetchResult(String semesterLabel) {
    return load<SemesterResult>(
      debugLabel: 'principal.semester_results',
      fromSupabase: () async {
        final row = await ApiClient.schema(DbSchema.principal)
            .from('semester_results')
            .select(
              'semester_label, overall_pass_percent, '
              'semester_result_departments(pass_percent, departments(code))',
            )
            .eq('semester_label', semesterLabel)
            .maybeSingle();

        // The label comes from a dropdown built out of this same table, so a
        // miss means the row was removed between the list loading and this
        // read. `single()` reported that as a raw driver error.
        if (row == null) {
          throw StateError(
            'No published result found for "$semesterLabel". It may have been '
            'withdrawn since the semester list was loaded.',
          );
        }

        final result = Map<String, dynamic>.from(row);
        final breakdown = result['semester_result_departments'];

        final byDepartment = <({String departmentCode, double passPercent})>[];
        if (breakdown is List) {
          for (final raw in breakdown) {
            final entry = Map<String, dynamic>.from(raw as Map);
            final dept = entry['departments'];
            final code = dept is Map
                ? Map<String, dynamic>.from(dept).strOr('code', '')
                : '';
            if (code.isEmpty) continue;
            byDepartment.add((
              departmentCode: code,
              passPercent: entry.doubleOr('pass_percent', 0),
            ));
          }
        }

        byDepartment.sort((a, b) => b.passPercent.compareTo(a.passPercent));

        return SemesterResult(
          semesterLabel: result.strOr('semester_label', semesterLabel),
          overallPassPercent: result.doubleOr('overall_pass_percent', 0),
          byDepartment: byDepartment,
        );
      },
    );
  }

  Future<Sourced<List<RankHolder>>> fetchRankHolders(String semesterLabel) {
    return load<List<RankHolder>>(
      debugLabel: 'principal.rank_holders',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        // The REST-to-SQL gateway supports embedded department reads, but not
        // PostgREST's `!inner` relation filter syntax. Resolve the selected
        // semester id first, then filter rank_holders on its real foreign key.
        final semesterRow = await ApiClient.schema(DbSchema.principal)
            .from('semester_results')
            .select('id')
            .eq('semester_label', semesterLabel)
            .maybeSingle();
        if (semesterRow == null) return const <RankHolder>[];

        final semesterId = Map<String, dynamic>.from(
          semesterRow,
        ).strOr('id', '');
        if (semesterId.isEmpty) return const <RankHolder>[];

        final rows = await ApiClient.schema(DbSchema.principal)
            .from('rank_holders')
            .select(
              'rank_position, student_name, student_roll_no, cgpa, '
              'departments(code)',
            )
            .eq('semester_result_id', semesterId)
            .order('rank_position', ascending: true);

        return [
          for (final raw in rows) _toRankHolder(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  RankHolder _toRankHolder(Map<String, dynamic> row) {
    final dept = row['departments'];
    final code = dept is Map
        ? Map<String, dynamic>.from(dept).strOr('code', '')
        : '';

    return RankHolder(
      rank: row.intOr('rank_position', 0),
      studentName: row.strOr('student_name', ''),
      rollNumber: row.strOr('student_roll_no', ''),
      // The rest of the app keys departments by the lowercase code.
      departmentId: code.toLowerCase(),
      cgpa: row.doubleOr('cgpa', 0),
    );
  }

  /// Highest and lowest mark actually recorded for each subject.
  ///
  /// `principal.subject_results` stores an average but no range, so the range
  /// is read from `faculty.marks`, which holds a mark per student per paper.
  /// Keyed on subject name because that is the only field the two share — the
  /// summary table carries no link to the marks rows.
  ///
  /// Expect most subjects to be missing from the result. The Faculty Portal
  /// has recorded marks for three papers, so the rest have no range to show
  /// and the table prints an em dash rather than inventing one.
  Future<Sourced<Map<String, ({double highest, double lowest})>>>
  fetchSubjectMarkRanges() {
    return load<Map<String, ({double highest, double lowest})>>(
      debugLabel: 'faculty.marks (per-subject range)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.faculty,
        ).from('marks').select('subject, total, is_absent');

        final ranges = <String, ({double highest, double lowest})>{};
        for (final raw in rows) {
          final row = Map<String, dynamic>.from(raw);
          final subject = row.strOr('subject', '').trim();
          if (subject.isEmpty) continue;
          // An absentee scored nothing; counting it as a low mark would
          // misreport the range of what the cohort actually achieved.
          if (row.boolOr('is_absent', false)) continue;

          final mark = row.doubleOr('total', 0);
          final current = ranges[subject];
          ranges[subject] = current == null
              ? (highest: mark, lowest: mark)
              : (
                  highest: mark > current.highest ? mark : current.highest,
                  lowest: mark < current.lowest ? mark : current.lowest,
                );
        }
        return ranges;
      },
    );
  }
}
