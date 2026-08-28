import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../../../core/theme/app_icons.dart';
import '../models/institution_overview.dart';
import '../models/institution_trend.dart';

/// Everything on the Institution screen that is not a live head count.
///
/// Head counts come from [DepartmentRepository] and its rollup view. What is
/// read here — KPI cards, multi-year trends, the enrolment mix, semester
/// performance, facilities and highlights — has no source anywhere else, so it
/// lives in `principal`.
class InstitutionRepository extends Repository {
  const InstitutionRepository();

  Future<Sourced<List<InstitutionKpi>>> fetchKpis() {
    return load<List<InstitutionKpi>>(
      debugLabel: 'principal.kpi_snapshots',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('kpi_snapshots')
            .select()
            .eq('module', 'institution')
            .order('display_order', ascending: true);

        return [for (final raw in rows) _toKpi(Map<String, dynamic>.from(raw))];
      },
    );
  }

  /// One trend series — admissions, academic growth, faculty or students.
  ///
  /// All four share a table and are separated by [series], because they are
  /// the same shape and four near-identical tables would drift apart.
  Future<Sourced<List<YearlyMetric>>> fetchTrend(String series) {
    return load<List<YearlyMetric>>(
      debugLabel: 'principal.institution_metrics ($series)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('institution_metrics')
            .select()
            .eq('series', series)
            .order('year', ascending: true);

        return [
          for (final raw in rows)
            YearlyMetric(
              year: Map<String, dynamic>.from(raw).strOr('year', ''),
              value: Map<String, dynamic>.from(raw).doubleOr('value', 0),
            ),
        ];
      },
    );
  }

  /// The academic years on record, most recent first.
  ///
  /// Read rather than hardcoded, so rolling into a new year is a row in
  /// `principal.academic_years` and not a code change.
  Future<Sourced<List<AcademicYear>>> fetchAcademicYears() {
    return load<List<AcademicYear>>(
      debugLabel: 'principal.academic_years',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('academic_years')
            .select('label, is_current')
            .order('start_date', ascending: false);

        return [
          for (final raw in rows)
            AcademicYear(
              label: Map<String, dynamic>.from(raw).strOr('label', ''),
              isCurrent: Map<String, dynamic>.from(
                raw,
              ).boolOr('is_current', false),
            ),
        ];
      },
    );
  }

  /// Faculty composition by employment status, counted from
  /// `faculty.faculties`.
  ///
  /// Counted rather than stored: the roster is the truth about who is employed
  /// on what basis, and a stored slice would go stale the moment somebody was
  /// appointed.
  ///
  /// `employment_type` is free text in their schema and arrives spelt several
  /// ways — "Permanent", "Permanent / Regular", "Full-Time Permanent", some
  /// with trailing newlines. [_employmentBand] collapses those, otherwise the
  /// chart would show four slices for one category.
  Future<Sourced<List<FacultyStatusSlice>>> fetchFacultyComposition() {
    return load<List<FacultyStatusSlice>>(
      debugLabel: 'faculty.faculties (employment_type)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.faculty,
        ).from('faculties').select('employment_type');

        final counts = <String, int>{};
        for (final raw in rows) {
          final band = _employmentBand(
            Map<String, dynamic>.from(raw).str('employment_type'),
          );
          counts[band] = (counts[band] ?? 0) + 1;
        }

        return [
          for (final entry in counts.entries)
            FacultyStatusSlice(label: entry.key, count: entry.value),
        ]..sort((a, b) => b.count.compareTo(a.count));
      },
    );
  }

  /// Collapses the many spellings of employment type into one band.
  static String _employmentBand(String? raw) {
    final text = (raw ?? '').trim().toLowerCase();
    if (text.isEmpty) return 'Not Recorded';
    if (text.contains('contract')) return 'Contract';
    if (text.contains('visiting')) return 'Visiting';
    if (text.contains('guest')) return 'Guest';
    if (text.contains('adjunct')) return 'Adjunct';
    if (text.contains('probation')) return 'Probationary';
    if (text.contains('permanent') || text.contains('regular')) {
      return 'Permanent';
    }
    // Kept visible rather than folded into Permanent — an unrecognised basis of
    // employment is worth someone noticing.
    return 'Other';
  }

  Future<Sourced<List<ProgramLevelEnrolment>>> fetchEnrolment() {
    return load<List<ProgramLevelEnrolment>>(
      debugLabel: 'principal.program_enrolments',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('program_enrolments').select();

        return [
          for (final raw in rows)
            ProgramLevelEnrolment(
              level: Map<String, dynamic>.from(raw).strOr('level', ''),
              currentYear: Map<String, dynamic>.from(
                raw,
              ).intOr('current_year_count', 0),
              previousYear: Map<String, dynamic>.from(
                raw,
              ).intOr('previous_year_count', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<SemesterPerformance>>> fetchSemesterPerformance() {
    return load<List<SemesterPerformance>>(
      debugLabel: 'principal.semester_performance',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('semester_performance')
            .select()
            .order('display_order', ascending: true);

        return [
          for (final raw in rows)
            SemesterPerformance(
              semester: Map<String, dynamic>.from(raw).strOr('semester', ''),
              passPercent: Map<String, dynamic>.from(
                raw,
              ).doubleOr('pass_percent', 0),
              averageSgpa: Map<String, dynamic>.from(
                raw,
              ).doubleOr('average_sgpa', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<FacilityStat>>> fetchFacilities() {
    return load<List<FacilityStat>>(
      debugLabel: 'principal.facility_stats',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('facility_stats')
            .select()
            .order('display_order', ascending: true);

        return [
          for (final raw in rows)
            FacilityStat(
              // Icons are stored as a name; the UI resolves it. Keeping
              // Flutter's IconData out of the database.
              icon: AppIcons.byName(
                Map<String, dynamic>.from(raw).strOr('icon_name', ''),
              ),
              label: Map<String, dynamic>.from(raw).strOr('label', ''),
              count: Map<String, dynamic>.from(raw).intOr('count', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<InstitutionHighlight>>> fetchHighlights() {
    return load<List<InstitutionHighlight>>(
      debugLabel: 'principal.institution_highlights',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('institution_highlights')
            .select()
            .order('display_order', ascending: true);

        return [
          for (final raw in rows)
            InstitutionHighlight(
              icon: AppIcons.byName(
                Map<String, dynamic>.from(raw).strOr('icon_name', ''),
              ),
              title: Map<String, dynamic>.from(raw).strOr('title', ''),
              detail: Map<String, dynamic>.from(raw).strOr('detail', ''),
            ),
        ];
      },
    );
  }

  InstitutionKpi _toKpi(Map<String, dynamic> row) => InstitutionKpi(
    label: row.strOr('label', ''),
    value: row.strOr('value', '—'),
    trendPercent: row.strOr('trend', ''),
    isPositive: row.boolOr('is_positive', true),
  );
}
