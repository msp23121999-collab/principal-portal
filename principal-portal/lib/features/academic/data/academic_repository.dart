import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/academic_performance.dart';

/// Reads the Academic Performance screen from `principal`.
///
/// Raw marks are not copied here — `faculty.marks` holds them and the Faculty
/// Portal owns them. What lives in `principal` is the institution-level
/// summary the Principal actually looks at: pass rates, grade and SGPA
/// distributions, outcome attainment, and the top and bottom performers.
///
/// Department codes are resolved by joining `principal.departments`, so the
/// screen shows `CSE` rather than a uuid.
class AcademicRepository extends Repository {
  const AcademicRepository();

  Future<Sourced<List<AcademicKpi>>> fetchKpis() {
    return load<List<AcademicKpi>>(
      debugLabel: 'principal.kpi_snapshots (academic)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('kpi_snapshots')
            .select()
            .eq('module', 'academic')
            .order('display_order', ascending: true);

        return [
          for (final raw in rows)
            AcademicKpi(
              label: Map<String, dynamic>.from(raw).strOr('label', ''),
              value: Map<String, dynamic>.from(raw).strOr('value', '—'),
              trend: Map<String, dynamic>.from(raw).strOr('trend', ''),
              isPositive: Map<String, dynamic>.from(
                raw,
              ).boolOr('is_positive', true),
            ),
        ];
      },
    );
  }

  /// Pass rate per department, current versus previous published semester.
  ///
  /// Both figures come from `semester_result_departments`, so the comparison
  /// is between two real semesters rather than an invented baseline.
  Future<Sourced<DepartmentPassComparison>> fetchDepartmentPassRates() {
    return load<DepartmentPassComparison>(
      debugLabel: 'principal.semester_result_departments',
      isEmpty: (comparison) => comparison.rates.isEmpty,
      fromSupabase: () async {
        final results = await ApiClient.schema(DbSchema.principal)
            .from('semester_results')
            .select('id, semester_label, published_on')
            .order('published_on', ascending: false)
            .limit(2);

        if (results.isEmpty) {
          return (
            currentLabel: '',
            previousLabel: null,
            rates: const <DepartmentPassRate>[],
          );
        }

        final currentRow = Map<String, dynamic>.from(results.first);
        final currentId = currentRow.strOr('id', '');
        // The labels travel with the figures so the chart legend names the
        // semesters actually plotted, rather than two years written in code.
        final currentLabel = currentRow.strOr('semester_label', '');

        final previousRow = results.length > 1
            ? Map<String, dynamic>.from(results[1])
            : null;
        final previousId = previousRow?.strOr('id', '') ?? '';
        final previousLabel = previousRow?.str('semester_label');

        final rows = await ApiClient.schema(DbSchema.principal)
            .from('semester_result_departments')
            .select('pass_percent, semester_result_id, departments(code)');

        // Group by department so the current and previous figures land on one
        // row, which is the shape the chart needs.
        final current = <String, double>{};
        final previous = <String, double>{};

        for (final raw in rows) {
          final row = Map<String, dynamic>.from(raw);
          final dept = _departmentCode(row);
          if (dept.isEmpty) continue;
          final resultId = row.strOr('semester_result_id', '');
          final percent = row.doubleOr('pass_percent', 0);

          if (resultId == currentId) current[dept] = percent;
          if (resultId == previousId) previous[dept] = percent;
        }

        final rates = [
          for (final entry in current.entries)
            DepartmentPassRate(
              department: entry.key,
              currentPercent: entry.value,
              previousPercent: previous[entry.key] ?? 0,
            ),
        ]..sort((a, b) => b.currentPercent.compareTo(a.currentPercent));

        return (
          currentLabel: currentLabel,
          previousLabel: previousLabel,
          rates: rates,
        );
      },
    );
  }

  Future<Sourced<List<SemesterSummary>>> fetchSemesterSummaries() {
    return load<List<SemesterSummary>>(
      debugLabel: 'principal.semester_summaries',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('semester_summaries')
            .select()
            .order('semester', ascending: true);

        return [
          for (final raw in rows)
            _toSemesterSummary(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<SubjectResult>>> fetchSubjectResults() {
    return load<List<SubjectResult>>(
      debugLabel: 'principal.subject_results',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('subject_results')
            .select('*, departments(code)')
            .order('subject_code', ascending: true);

        return [
          for (final raw in rows)
            _toSubjectResult(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<SgpaBand>>> fetchSgpaBands() {
    return _simpleList(
      table: 'sgpa_bands',
      map: (row) => SgpaBand(
        label: row.strOr('label', ''),
        studentCount: row.intOr('student_count', 0),
      ),
    );
  }

  Future<Sourced<List<GradeSlice>>> fetchGradeSlices() {
    return _simpleList(
      table: 'grade_slices',
      map: (row) => GradeSlice(
        grade: row.strOr('grade', ''),
        studentCount: row.intOr('student_count', 0),
      ),
    );
  }

  Future<Sourced<List<AttainmentLevel>>> fetchAttainmentLevels() {
    return _simpleList(
      table: 'attainment_levels',
      map: (row) => AttainmentLevel(
        label: row.strOr('label', ''),
        courseOutcomes: row.intOr('course_outcomes', 0),
        programOutcomes: row.intOr('program_outcomes', 0),
      ),
      ordered: false,
    );
  }

  Future<Sourced<List<AtRiskReason>>> fetchAtRiskReasons() {
    return _simpleList(
      table: 'at_risk_reasons',
      map: (row) => AtRiskReason(
        reason: row.strOr('reason', ''),
        studentCount: row.intOr('student_count', 0),
      ),
      ordered: false,
    );
  }

  Future<Sourced<List<YearlyPassRate>>> fetchYearlyPassRates() {
    return _simpleList(
      table: 'yearly_pass_rates',
      map: (row) => YearlyPassRate(
        year: row.strOr('year', ''),
        passPercent: row.doubleOr('pass_percent', 0),
      ),
      orderColumn: 'year',
    );
  }

  /// Shared shape for the small lookup tables behind the charts — each is a
  /// flat select with one mapping function, so spelling out six near-identical
  /// methods would be noise.
  Future<Sourced<List<T>>> _simpleList<T>({
    required String table,
    required T Function(Map<String, dynamic>) map,
    String orderColumn = 'display_order',
    bool ordered = true,
  }) {
    return load<List<T>>(
      debugLabel: 'principal.$table',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final query = ApiClient.schema(
          DbSchema.principal,
        ).from(table).select();
        // `ascending: true` stated, never left to the default. postgrest's
        // `.order()` defaults to DESCENDING, and because the column name here
        // is a variable this call was missed when the other 24 were made
        // explicit. It reversed `sgpa_bands`, `grade_slices` and
        // `yearly_pass_rates` — which drew the trend chart backwards and swapped
        // the "distinction" and "below 6.00" cards on the SGPA tab.
        final rows = ordered
            ? await query.order(orderColumn, ascending: true)
            : await query;
        return [for (final raw in rows) map(Map<String, dynamic>.from(raw))];
      },
    );
  }

  /// PostgREST returns an embedded join as a nested object.
  String _departmentCode(Map<String, dynamic> row) {
    final dept = row['departments'];
    if (dept is Map) {
      return Map<String, dynamic>.from(dept).strOr('code', '');
    }
    return '';
  }

  SemesterSummary _toSemesterSummary(Map<String, dynamic> row) =>
      SemesterSummary(
        semester: row.strOr('semester', ''),
        appeared: row.intOr('appeared', 0),
        passed: row.intOr('passed', 0),
        averageSgpa: row.doubleOr('average_sgpa', 0),
        averageCgpa: row.doubleOr('average_cgpa', 0),
        backlogs: row.intOr('backlogs', 0),
        topPerformer: row.strOr('top_performer_name', '—'),
        topPerformerCgpa: row.doubleOr('top_performer_cgpa', 0),
      );

  SubjectResult _toSubjectResult(Map<String, dynamic> row) => SubjectResult(
    code: row.strOr('subject_code', ''),
    name: row.strOr('subject_name', ''),
    departmentCode: _departmentCode(row),
    semester: row.strOr('semester', ''),
    // The table stores an employee id; the roster lives in another schema.
    // Showing the id beats showing a blank column.
    faculty: row.strOr('faculty_employee_id', '—'),
    appeared: row.intOr('appeared', 0),
    passed: row.intOr('passed', 0),
    averageMarks: row.doubleOr('average_marks', 0),
  );
}
