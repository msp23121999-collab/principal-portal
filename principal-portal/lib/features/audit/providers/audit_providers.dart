import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/audit_repository.dart';
import '../models/audit.dart';

final auditRepositoryProvider = Provider((ref) => const AuditRepository());

/// Module filter for the audit trail, null meaning every module.
final auditModuleFilterProvider = StateProvider<String?>((ref) => null);

/// Severity filter for the audit trail, null meaning every severity.
final auditSeverityFilterProvider = StateProvider<AuditSeverity?>(
  (ref) => null,
);

/// Free-text filter across actor, action, and description.
final auditSearchProvider = StateProvider<String>((ref) => '');

/// The whole trail, unfiltered — the source the filtered view reads.
final _allAuditEntriesProvider = FutureProvider<List<AuditEntry>>((ref) async {
  return (await ref.watch(auditRepositoryProvider).fetchEntries()).value;
});

/// Distinct modules actually present in the trail, for the filter dropdown.
///
/// Derived from the entries rather than hardcoded, so the dropdown can never
/// offer a module with nothing behind it.
final auditModulesProvider = Provider<List<String>>((ref) {
  final entries = ref.watch(_allAuditEntriesProvider).valueOrNull ?? const [];
  return entries.map((e) => e.module).toSet().toList()..sort();
});

/// The audit trail, newest first, after every active filter.
final auditEntriesProvider = FutureProvider<List<AuditEntry>>((ref) async {
  final module = ref.watch(auditModuleFilterProvider);
  final severity = ref.watch(auditSeverityFilterProvider);
  final query = ref.watch(auditSearchProvider).trim().toLowerCase();
  final entries = await ref.watch(_allAuditEntriesProvider.future);

  return entries.where((entry) {
    final matchesModule = module == null || entry.module == module;
    final matchesSeverity = severity == null || entry.severity == severity;
    final matchesQuery =
        query.isEmpty ||
        entry.actor.toLowerCase().contains(query) ||
        entry.description.toLowerCase().contains(query) ||
        entry.action.label.toLowerCase().contains(query);
    return matchesModule && matchesSeverity && matchesQuery;
  }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

/// Weakest areas first — what a Principal needs to see before the rest.
final complianceAreasProvider = FutureProvider<List<ComplianceArea>>((
  ref,
) async {
  final sourced = await ref
      .watch(auditRepositoryProvider)
      .fetchComplianceAreas();
  return [...sourced.value]
    ..sort((a, b) => a.scorePercent.compareTo(b.scorePercent));
});

final inspectionsProvider = FutureProvider<List<InspectionReport>>((ref) async {
  final sourced = await ref.watch(auditRepositoryProvider).fetchInspections();
  return [...sourced.value]
    ..sort((a, b) => b.inspectedOn.compareTo(a.inspectedOn));
});

/// Institution-wide audit figures, derived once and read by the screen header
/// and three of the tabs.
///
/// Computed here rather than in each widget so the header and the tabs cannot
/// disagree about the same number — a Principal reading "82% compliant" at the
/// top and a different figure on the tab below would trust neither.
///
/// Deliberately unfiltered: these describe the institution, not the current
/// selection, so they hold still while the user browses.
typedef AuditSummary = ({
  int totalActions,
  int criticalActions,
  double averageComplianceScore,
  int compliantAreas,
  int areasNeedingAction,
  int openInspectionFindings,
  int overduePolicyReviews,
  int openPolicyIssues,
});

final auditSummaryProvider = FutureProvider<AuditSummary>((ref) async {
  final entries = await ref.watch(_allAuditEntriesProvider.future);
  final areas = await ref.watch(complianceAreasProvider.future);
  final inspections = await ref.watch(inspectionsProvider.future);
  final policies = await ref.watch(policiesProvider.future);

  final now = DateTime.now();

  return (
    totalActions: entries.length,
    criticalActions: entries
        .where((e) => e.severity == AuditSeverity.critical)
        .length,
    // Averaged over each area's own maximum, so an area scored out of 10 and
    // one scored out of 100 carry the same weight.
    averageComplianceScore: areas.isEmpty
        ? 0.0
        : areas.fold(0.0, (sum, a) => sum + a.scorePercent) / areas.length,
    compliantAreas: areas
        .where((a) => a.state == ComplianceState.compliant)
        .length,
    areasNeedingAction: areas
        .where(
          (a) =>
              a.state == ComplianceState.atRisk ||
              a.state == ComplianceState.nonCompliant,
        )
        .length,
    // Findings from inspections that have not been closed out. A closed
    // inspection's findings are settled and must not keep counting.
    openInspectionFindings: inspections
        .where((i) => i.closedOn == null)
        .fold(0, (sum, i) => sum + i.totalFindings),
    overduePolicyReviews: policies.where((p) => p.isReviewOverdue(now)).length,
    openPolicyIssues: policies.fold(0, (sum, p) => sum + p.openIssues),
  );
});

/// Overdue reviews first, then by adherence.
///
/// "Overdue" is judged against today rather than a fixed reference date, so a
/// policy becomes overdue as time passes instead of staying frozen.
final policiesProvider = FutureProvider<List<PolicyAdherence>>((ref) async {
  final now = DateTime.now();
  final sourced = await ref.watch(auditRepositoryProvider).fetchPolicies();

  return [...sourced.value]..sort((a, b) {
    final aOverdue = a.isReviewOverdue(now);
    final bOverdue = b.isReviewOverdue(now);
    if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
    return a.adherencePercent.compareTo(b.adherencePercent);
  });
});
