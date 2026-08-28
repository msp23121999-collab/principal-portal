import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/utils/batch_parser.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../institution/providers/institution_providers.dart';
import '../../students/providers/student_providers.dart';
import '../data/placement_repository.dart';
import '../models/company.dart';
import '../models/placement_drive.dart';
import '../models/placement_record.dart';

final placementRepositoryProvider = Provider(
  (ref) => const PlacementRepository(),
);

final companiesProvider = FutureProvider<List<Company>>((ref) async {
  return (await ref.watch(placementRepositoryProvider).fetchCompanies()).value;
});

final placementRecordsProvider = FutureProvider<List<PlacementRecord>>((
  ref,
) async {
  return (await ref.watch(placementRepositoryProvider).fetchPlacements()).value;
});

/// Eligible and placed counts for the summary KPI row.
///
/// Both come from the department rollup, which counts the live student roll,
/// so this reconciles with every other page reporting placement rather than
/// pairing a seeded hire list against a differently-sourced base.
final placementEligibilityProvider =
    FutureProvider<({int eligible, int placed})>((ref) async {
      final departments = await ref.watch(departmentsProvider.future);
      final placements = await ref.watch(placementRecordsProvider.future);

      return (
        eligible: departments.fold(0, (sum, d) => sum + d.studentCount),
        placed: placements.length,
      );
    });

/// Drive stage filter, null meaning every stage.
final driveStageFilterProvider = StateProvider<DriveStage?>((ref) => null);

final _allDrivesProvider = FutureProvider<List<PlacementDrive>>((ref) async {
  return (await ref.watch(placementRepositoryProvider).fetchDrives()).value;
});

final placementDrivesProvider = FutureProvider<List<PlacementDrive>>((
  ref,
) async {
  final stage = ref.watch(driveStageFilterProvider);
  final drives = await ref.watch(_allDrivesProvider.future);
  if (stage == null) return drives;
  return drives.where((drive) => drive.stage == stage).toList();
});

final internshipsProvider = FutureProvider<List<InternshipRecord>>((ref) async {
  return (await ref.watch(placementRepositoryProvider).fetchInternships())
      .value;
});

/// Offers bucketed by package.
///
/// Derived from the offers themselves rather than stored, so a band can never
/// disagree with the records it is counting.
final packageBandsProvider = FutureProvider<List<PackageBand>>((ref) async {
  final placements = await ref.watch(placementRecordsProvider.future);

  const bands = [
    (label: 'Below 4 LPA', min: 0.0, max: 4.0),
    (label: '4 – 6 LPA', min: 4.0, max: 6.0),
    (label: '6 – 10 LPA', min: 6.0, max: 10.0),
    (label: '10 – 20 LPA', min: 10.0, max: 20.0),
    (label: 'Above 20 LPA', min: 20.0, max: double.infinity),
  ];

  return [
    for (final band in bands)
      PackageBand(
        label: band.label,
        minLpa: band.min,
        maxLpa: band.max == double.infinity ? null : band.max,
        offerCount: placements
            .where((p) => p.packageLpa >= band.min && p.packageLpa < band.max)
            .length,
      ),
  ];
});

/// The placement season at a glance, for the drive summary cards.
///
/// Derived from the drives and internships the tabs already show, so no figure
/// here can drift from the rows beneath it.
typedef DriveSummary = ({
  int drivesHeld,
  int upcomingDrives,
  int registrations,
  int offers,
  int internshipStudents,
  int paidInternshipStudents,
});

final driveSummaryProvider = FutureProvider<DriveSummary>((ref) async {
  final drives = await ref.watch(_allDrivesProvider.future);
  final internships = await ref.watch(internshipsProvider.future);

  // A cancelled drive was never held, so it is excluded from the count rather
  // than inflating the season's total.
  final held = drives.where((d) => d.stage != DriveStage.cancelled);

  return (
    drivesHeld: held.length,
    upcomingDrives: drives.where((d) => d.stage == DriveStage.scheduled).length,
    registrations: drives.fold(0, (sum, d) => sum + d.registered),
    offers: drives.fold(0, (sum, d) => sum + d.offersMade),
    internshipStudents: internships.fold(0, (sum, i) => sum + i.students),
    paidInternshipStudents: internships
        .where((i) => i.monthlyStipend > 0)
        .fold(0, (sum, i) => sum + i.students),
  );
});

// ---------------------------------------------------------------------------
// Filtered placements — sections 9.1 to 9.3
// ---------------------------------------------------------------------------

/// Placement offers matching the portal filters that apply to them.
///
/// Department, batch and programme narrow an offer; year of study, semester
/// and subject do not — a placement belongs to a graduating student, not to a
/// semester — so those are ignored here rather than silently emptying the list.
///
/// Programme level is resolved by looking the student up on the roll: an offer
/// records a roll number, not a degree.
final filteredPlacementsProvider = Provider<AsyncValue<List<PlacementRecord>>>((
  ref,
) {
  final filters = ref.watch(portalFiltersProvider);
  final roster = ref.watch(studentListProvider).valueOrNull ?? const [];

  final levelByRoll = {
    for (final s in roster)
      if (s.programLevel != null) s.rollNumber: s.programLevel!,
  };

  return ref.watch(placementRecordsProvider).whenData((records) {
    return records.where((record) {
      if (filters.departmentCode != null &&
          DepartmentNormalizer.codeFor(record.departmentId) !=
              filters.departmentCode) {
        return false;
      }
      if (filters.batch != null &&
          record.batchStartYear !=
              BatchParser.startYearFromBatch(filters.batch)) {
        return false;
      }
      if (filters.programLevel != null) {
        final level = levelByRoll[record.rollNumber];
        // Unknown rather than excluded: an offer for somebody no longer on
        // the roll should not vanish from the department's total.
        if (level != null && level != filters.programLevel) return false;
      }
      return true;
    }).toList();
  });
});

/// The single highest and lowest offer in scope, with who and where.
///
/// Section 9.2 asks for the student, department, batch and company behind each
/// figure rather than the number alone — a package with no name attached is
/// not something a Principal can act on.
typedef PackageExtreme = ({
  double packageLpa,
  String studentName,
  String rollNumber,
  String departmentCode,
  String? batchRange,
  String companyName,
});

typedef PackageExtremes = ({PackageExtreme? highest, PackageExtreme? lowest});

final packageExtremesProvider = Provider<AsyncValue<PackageExtremes>>((ref) {
  return ref.watch(filteredPlacementsProvider).whenData((records) {
    if (records.isEmpty) return (highest: null, lowest: null);

    PackageExtreme toExtreme(PlacementRecord r) => (
      packageLpa: r.packageLpa,
      studentName: r.studentName,
      rollNumber: r.rollNumber,
      departmentCode: DepartmentNormalizer.codeFor(r.departmentId),
      batchRange: r.batchRange,
      companyName: r.companyName,
    );

    final sorted = [...records]
      ..sort((a, b) => a.packageLpa.compareTo(b.packageLpa));

    return (highest: toExtreme(sorted.last), lowest: toExtreme(sorted.first));
  });
});

/// Highest, lowest and average package per batch and department.
///
/// The table section 9.3 describes. Batch comes from the register number, so
/// offers whose roll number carries no year are grouped under "Unknown" rather
/// than dropped — a placement that happened is a fact, even if its batch
/// cannot be read.
typedef BatchPackageRow = ({
  String batch,
  String departmentCode,
  int offers,
  double highestLpa,
  double lowestLpa,
  double averageLpa,
});

final batchPackageAnalysisProvider =
    Provider<AsyncValue<List<BatchPackageRow>>>((ref) {
      return ref.watch(filteredPlacementsProvider).whenData((records) {
        final grouped = <String, List<PlacementRecord>>{};
        for (final record in records) {
          final batch = record.batchRange ?? 'Unknown';
          final dept = DepartmentNormalizer.codeFor(record.departmentId);
          grouped.putIfAbsent('$batch|$dept', () => []).add(record);
        }

        final rows = <BatchPackageRow>[];
        for (final entry in grouped.entries) {
          final parts = entry.key.split('|');
          final packages = [for (final r in entry.value) r.packageLpa];
          rows.add((
            batch: parts[0],
            departmentCode: parts[1],
            offers: entry.value.length,
            highestLpa: packages.reduce((a, b) => a > b ? a : b),
            lowestLpa: packages.reduce((a, b) => a < b ? a : b),
            averageLpa: packages.reduce((a, b) => a + b) / packages.length,
          ));
        }

        // Most recent batch first, then department, so the current cohort is
        // what the Principal reads without scrolling.
        rows.sort((a, b) {
          final byBatch = b.batch.compareTo(a.batch);
          return byBatch != 0
              ? byBatch
              : a.departmentCode.compareTo(b.departmentCode);
        });
        return rows;
      });
    });
