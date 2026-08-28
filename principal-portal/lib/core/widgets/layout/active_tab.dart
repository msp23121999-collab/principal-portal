import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which tab a tabbed page is currently showing.
///
/// Exists so a header button can act on **what the Principal is looking at**.
/// Accreditation, Finance and Audit each put one "Export" button above four
/// tabs, and "export this page" is meaningless there — the four tabs hold four
/// unrelated tables. Exporting the active one is what a user means when they
/// press it.
///
/// Keyed by page rather than one shared value, so moving between two tabbed
/// screens does not carry one page's tab index onto the other.
///
/// Not autoDispose: [StatefulShellRoute] keeps every branch alive so each
/// screen holds its scroll position and selected tab, and this must survive
/// alongside it. A handful of ints is not worth reclaiming.
final activeTabProvider = StateProvider.family<int, String>(
  (ref, pageKey) => 0,
);

/// Page keys for [activeTabProvider]. Constants rather than loose strings so a
/// typo cannot silently give a screen its own private, always-zero index.
class TabbedPageKeys {
  TabbedPageKeys._();

  static const String accreditation = 'accreditation';
  static const String approvals = 'approvals';
  static const String audit = 'audit';
  static const String departmentPerformance = 'department-performance';
  static const String examinations = 'examinations';
  static const String finance = 'finance';
  static const String research = 'research';
}
