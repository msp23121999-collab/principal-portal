import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../faculty/models/faculty.dart';
import '../models/research.dart';

/// Reads Research & Innovation from two places.
///
/// Publications and patents already exist as `faculty.research_publications`
/// and `faculty.patents`, owned by the Faculty Portal and read here rather
/// than copied. Funded projects and consultancy have no source anywhere, so
/// those live in `principal`.
///
/// Neither of the Faculty tables records a department — they identify work by
/// `faculty_employee_id`. The department is resolved by looking the author up
/// in the roster, which is why [fetchPublications] takes it as an argument.
///
/// Expect these screens to look sparse: the Faculty Portal has recorded six
/// publications and no patents. That is what the institution actually has, and
/// showing it honestly beats padding it.
class ResearchRepository extends Repository {
  const ResearchRepository();

  static PublicationType _typeFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'conference':
        return PublicationType.conference;
      case 'book_chapter':
      case 'book chapter':
        return PublicationType.bookChapter;
      default:
        return PublicationType.journal;
    }
  }

  static PublicationIndex _indexFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'scopus':
        return PublicationIndex.scopus;
      case 'web of science':
      case 'web_of_science':
      case 'wos':
        return PublicationIndex.webOfScience;
      case 'ugc care':
      case 'ugc_care':
      case 'ugc-care':
        return PublicationIndex.ugcCare;
      default:
        return PublicationIndex.other;
    }
  }

  static PatentStage _patentStageFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'granted':
        return PatentStage.granted;
      case 'published':
        return PatentStage.published;
      default:
        return PatentStage.filed;
    }
  }

  static ProjectStage _projectStageFrom(String? value) {
    switch (value) {
      case 'ongoing':
        return ProjectStage.ongoing;
      case 'completed':
        return ProjectStage.completed;
      default:
        return ProjectStage.sanctioned;
    }
  }

  /// Employee id -> normalised department code, for resolving authorship.
  Map<String, String> _departmentsByEmployee(List<Faculty> roster) => {
    for (final member in roster)
      member.id: DepartmentNormalizer.codeFor(member.departmentId),
  };

  Future<Sourced<List<Publication>>> fetchPublications(List<Faculty> roster) {
    return load<List<Publication>>(
      debugLabel: 'faculty.research_publications',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.faculty,
        ).from('research_publications').select();

        final byEmployee = _departmentsByEmployee(roster);

        return [
          for (final raw in rows)
            _toPublication(Map<String, dynamic>.from(raw), byEmployee),
        ];
      },
    );
  }

  Future<Sourced<List<Patent>>> fetchPatents(List<Faculty> roster) {
    return load<List<Patent>>(
      debugLabel: 'faculty.patents',
      // The table exists but is empty. Falling back to sample would be a lie —
      // the institution has filed no patents, and the screen should say so.
      isEmpty: null,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.faculty,
        ).from('patents').select();

        final byEmployee = _departmentsByEmployee(roster);

        return [
          for (final raw in rows)
            _toPatent(Map<String, dynamic>.from(raw), byEmployee),
        ];
      },
    );
  }

  Future<Sourced<List<FundedProject>>> fetchFundedProjects() {
    return load<List<FundedProject>>(
      debugLabel: 'principal.funded_projects',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('funded_projects')
            .select('*, departments(code)')
            .order('sanctioned_on', ascending: false);

        return [
          for (final raw in rows)
            _toFundedProject(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<ConsultancyProject>>> fetchConsultancy() {
    return load<List<ConsultancyProject>>(
      debugLabel: 'principal.consultancy_projects',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('consultancy_projects')
            .select('*, departments(code)')
            .order('revenue', ascending: false);

        return [
          for (final raw in rows)
            ConsultancyProject(
              title: Map<String, dynamic>.from(raw).strOr('title', ''),
              client: Map<String, dynamic>.from(raw).strOr('client', ''),
              departmentCode: _deptCode(Map<String, dynamic>.from(raw)),
              leadFaculty: Map<String, dynamic>.from(
                raw,
              ).strOr('lead_faculty', '—'),
              revenue: Map<String, dynamic>.from(raw).doubleOr('revenue', 0),
              stage: _projectStageFrom(
                Map<String, dynamic>.from(raw).str('stage'),
              ),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<ResearchYearOutput>>> fetchYearlyOutput() {
    return load<List<ResearchYearOutput>>(
      debugLabel: 'principal.research_year_output',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('research_year_output').select().order('year', ascending: true);

        return [
          for (final raw in rows)
            ResearchYearOutput(
              year: Map<String, dynamic>.from(raw).strOr('year', ''),
              publications: Map<String, dynamic>.from(
                raw,
              ).intOr('publications', 0),
              patents: Map<String, dynamic>.from(raw).intOr('patents', 0),
              projects: Map<String, dynamic>.from(raw).intOr('projects', 0),
            ),
        ];
      },
    );
  }

  String _deptCode(Map<String, dynamic> row) {
    final dept = row['departments'];
    return dept is Map ? Map<String, dynamic>.from(dept).strOr('code', '') : '';
  }

  Publication _toPublication(
    Map<String, dynamic> row,
    Map<String, String> byEmployee,
  ) {
    final employeeId = row.strOr('faculty_employee_id', '');
    final date = row.dateOr('publication_date', DateTime.now());

    return Publication(
      title: row.strOr('title', ''),
      // `authors` is a free-text list; the employee id is the reliable link.
      leadAuthor: row.strOr('authors', employeeId),
      venue: row.strOr('journal_or_conf_name', '—'),
      departmentCode: byEmployee[employeeId] ?? '—',
      type: _typeFrom(row.str('pub_type')),
      index: _indexFrom(row.str('indexing')),
      year: date.year,
      // Citation counts are not recorded in their table. Zero rather than a
      // guess — an invented citation count is a claim about impact.
      citations: 0,
      impactFactor: row.doubleOr('impact_factor', 0),
    );
  }

  Patent _toPatent(Map<String, dynamic> row, Map<String, String> byEmployee) {
    final employeeId = row.strOr('faculty_employee_id', '');

    return Patent(
      title: row.strOr('title', ''),
      leadInventor: employeeId.isEmpty ? '—' : employeeId,
      departmentCode: byEmployee[employeeId] ?? '—',
      applicationNumber: row.strOr('application_no', '—'),
      filedOn: row.dateOr('filing_date', DateTime.now()),
      stage: _patentStageFrom(row.str('patent_status')),
      grantedOn: row.str('grant_date') == null
          ? null
          : row.dateOr('grant_date', DateTime.now()),
    );
  }

  FundedProject _toFundedProject(Map<String, dynamic> row) => FundedProject(
    title: row.strOr('title', ''),
    principalInvestigator: row.strOr('principal_investigator', '—'),
    departmentCode: _deptCode(row),
    agency: row.strOr('agency', '—'),
    sanctionedAmount: row.doubleOr('sanctioned_amount', 0),
    durationMonths: row.intOr('duration_months', 0),
    sanctionedOn: row.dateOr('sanctioned_on', DateTime.now()),
    stage: _projectStageFrom(row.str('stage')),
  );
}
