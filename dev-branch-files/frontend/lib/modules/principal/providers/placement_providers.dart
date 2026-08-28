import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/department_mock_data.dart';
import '../data/placement_mock_data.dart';
import '../models/company.dart';
import '../models/placement_record.dart';

final companiesProvider = FutureProvider<List<Company>>((ref) {
  return mockDelay(() => PlacementMockData.companies);
});

final placementRecordsProvider = FutureProvider<List<PlacementRecord>>((ref) {
  return mockDelay(PlacementMockData.placements);
});

/// Total eligible students (institution-wide) vs. placed, for the summary
/// KPI row — eligible figure derived from DepartmentMockData rather than a
/// hardcoded constant.
final placementEligibilityProvider = Provider<({int eligible, int placed})>((
  ref,
) {
  final eligible = (DepartmentMockData.totalStudents * 0.28).round();
  return (eligible: eligible, placed: PlacementMockData.totalPlaced);
});
