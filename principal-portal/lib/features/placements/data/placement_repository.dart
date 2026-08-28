import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/company.dart';
import '../models/placement_drive.dart';
import '../models/placement_record.dart';

/// Reads Placement Analytics from `principal`.
///
/// `student.placements` and `student.placement_applications` exist, but they
/// model a job opening a student can apply to. The Principal reviews the
/// season: which companies came, how many offers, at what packages. That is a
/// different question, so it has its own tables.
class PlacementRepository extends Repository {
  const PlacementRepository();

  static DriveStage _stageFrom(String? value) {
    switch (value) {
      case 'ongoing':
        return DriveStage.ongoing;
      case 'completed':
        return DriveStage.completed;
      case 'cancelled':
        return DriveStage.cancelled;
      default:
        return DriveStage.scheduled;
    }
  }

  Future<Sourced<List<Company>>> fetchCompanies() {
    return load<List<Company>>(
      debugLabel: 'principal.companies',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('companies').select().order('students_hired', ascending: false);

        return [
          for (final raw in rows)
            Company(
              name: Map<String, dynamic>.from(raw).strOr('name', ''),
              sector: Map<String, dynamic>.from(raw).strOr('sector', ''),
              studentsHired: Map<String, dynamic>.from(
                raw,
              ).intOr('students_hired', 0),
              avgPackageLpa: Map<String, dynamic>.from(
                raw,
              ).doubleOr('avg_package_lpa', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<PlacementRecord>>> fetchPlacements() {
    return load<List<PlacementRecord>>(
      debugLabel: 'principal.placement_records',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('placement_records')
            .select('*, departments(code), companies(name)')
            .order('offer_date', ascending: false);

        return [
          for (final raw in rows) _toPlacement(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<PlacementDrive>>> fetchDrives() {
    return load<List<PlacementDrive>>(
      debugLabel: 'principal.placement_drives',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('placement_drives')
            .select(
              '*, companies(name), '
              'placement_drive_departments(departments(code))',
            )
            .order('visit_date', ascending: false);

        return [
          for (final raw in rows) _toDrive(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<InternshipRecord>>> fetchInternships() {
    return load<List<InternshipRecord>>(
      debugLabel: 'principal.internship_records',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('internship_records')
            .select('*, departments(code), companies(name)');

        return [
          for (final raw in rows) _toInternship(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  String _nested(Map<String, dynamic> row, String table, String field) {
    final value = row[table];
    if (value is Map) {
      return Map<String, dynamic>.from(value).strOr(field, '');
    }
    return '';
  }

  PlacementRecord _toPlacement(Map<String, dynamic> row) => PlacementRecord(
    studentName: row.strOr('student_name', ''),
    rollNumber: row.strOr('student_roll_no', ''),
    departmentId: _nested(row, 'departments', 'code').toLowerCase(),
    companyName: _nested(row, 'companies', 'name'),
    packageLpa: row.doubleOr('package_lpa', 0),
    offerDate: row.dateOr('offer_date', DateTime.now()),
  );

  PlacementDrive _toDrive(Map<String, dynamic> row) {
    // `eligibleDepartments` was a List<String> on the model; in the database
    // it is a join table, which arrives as a list of nested objects.
    final eligible = <String>[];
    final links = row['placement_drive_departments'];
    if (links is List) {
      for (final link in links) {
        final code = _nested(
          Map<String, dynamic>.from(link as Map),
          'departments',
          'code',
        );
        if (code.isNotEmpty) eligible.add(code);
      }
    }

    return PlacementDrive(
      companyName: _nested(row, 'companies', 'name'),
      role: row.strOr('role', ''),
      visitDate: row.dateOr('visit_date', DateTime.now()),
      eligibleDepartments: eligible,
      registered: row.intOr('registered', 0),
      shortlisted: row.intOr('shortlisted', 0),
      offersMade: row.intOr('offers_made', 0),
      packageLpa: row.doubleOr('package_lpa', 0),
      stage: _stageFrom(row.str('stage')),
    );
  }

  InternshipRecord _toInternship(Map<String, dynamic> row) => InternshipRecord(
    companyName: _nested(row, 'companies', 'name'),
    domain: row.strOr('domain', ''),
    departmentCode: _nested(row, 'departments', 'code'),
    students: row.intOr('students', 0),
    durationWeeks: row.intOr('duration_weeks', 0),
    monthlyStipend: row.doubleOr('monthly_stipend', 0),
    convertsToOffer: row.boolOr('converts_to_offer', false),
  );
}
