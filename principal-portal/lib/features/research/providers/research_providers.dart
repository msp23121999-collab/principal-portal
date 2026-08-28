import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../faculty/providers/faculty_providers.dart';
import '../data/research_repository.dart';
import '../models/research.dart';

final researchRepositoryProvider = Provider(
  (ref) => const ResearchRepository(),
);

final researchOutputProvider = FutureProvider<List<ResearchYearOutput>>((
  ref,
) async {
  return (await ref.watch(researchRepositoryProvider).fetchYearlyOutput())
      .value;
});

/// Publications, read from the Faculty Portal's table.
///
/// The roster is fetched alongside because their table records an employee id
/// but no department; the department is resolved by looking the author up.
final _allPublicationsProvider = FutureProvider<List<Publication>>((ref) async {
  final roster = await ref.watch(facultyListProvider.future);
  return (await ref.watch(researchRepositoryProvider).fetchPublications(roster))
      .value;
});

final patentsProvider = FutureProvider<List<Patent>>((ref) async {
  final roster = await ref.watch(facultyListProvider.future);
  return (await ref.watch(researchRepositoryProvider).fetchPatents(roster))
      .value;
});

final fundedProjectsProvider = FutureProvider<List<FundedProject>>((ref) async {
  return (await ref.watch(researchRepositoryProvider).fetchFundedProjects())
      .value;
});

final consultancyProvider = FutureProvider<List<ConsultancyProject>>((
  ref,
) async {
  return (await ref.watch(researchRepositoryProvider).fetchConsultancy()).value;
});

/// Publication count per department, counted from the publications themselves
/// so the chart cannot disagree with the table beneath it.
final publicationsByDepartmentProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final publications = await ref.watch(_allPublicationsProvider.future);
  final counts = <String, int>{};
  for (final publication in publications) {
    counts.update(
      publication.departmentCode,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }
  return counts;
});

/// Index filter for the publications table, null meaning every index.
final publicationIndexFilterProvider = StateProvider<PublicationIndex?>(
  (ref) => null,
);

/// Free-text filter across title, author, venue, and department.
final publicationSearchProvider = StateProvider<String>((ref) => '');

final publicationsProvider = FutureProvider<List<Publication>>((ref) async {
  final index = ref.watch(publicationIndexFilterProvider);
  final query = ref.watch(publicationSearchProvider).trim().toLowerCase();
  final publications = await ref.watch(_allPublicationsProvider.future);

  return publications.where((publication) {
    final matchesIndex = index == null || publication.index == index;
    final matchesQuery =
        query.isEmpty ||
        publication.title.toLowerCase().contains(query) ||
        publication.leadAuthor.toLowerCase().contains(query) ||
        publication.venue.toLowerCase().contains(query) ||
        publication.departmentCode.toLowerCase().contains(query);
    return matchesIndex && matchesQuery;
  }).toList()..sort((a, b) => b.year.compareTo(a.year));
});

/// Research output at a glance, for the overview KPI row.
///
/// Counted from the publication, patent and project lists rather than stored.
/// Citations come to zero because the Faculty Portal does not record them —
/// see [ResearchRepository]. An invented citation count would be a claim about
/// impact, so the card reports what is known.
typedef ResearchSummary = ({
  int publications,
  int patents,
  int grantedPatents,
  int fundedProjects,
  int ongoingProjects,
  double totalFunding,
  double consultancyRevenue,
  int citations,
});

final researchSummaryProvider = FutureProvider<ResearchSummary>((ref) async {
  final publications = await ref.watch(_allPublicationsProvider.future);
  final patents = await ref.watch(patentsProvider.future);
  final projects = await ref.watch(fundedProjectsProvider.future);
  final consultancy = await ref.watch(consultancyProvider.future);

  return (
    publications: publications.length,
    patents: patents.length,
    grantedPatents: patents.where((p) => p.stage == PatentStage.granted).length,
    fundedProjects: projects.length,
    ongoingProjects: projects
        .where((p) => p.stage == ProjectStage.ongoing)
        .length,
    totalFunding: projects.fold(0.0, (sum, p) => sum + p.sanctionedAmount),
    consultancyRevenue: consultancy.fold(0.0, (sum, c) => sum + c.revenue),
    citations: publications.fold(0, (sum, p) => sum + p.citations),
  );
});
