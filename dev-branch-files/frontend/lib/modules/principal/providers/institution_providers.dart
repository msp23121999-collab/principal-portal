import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/department_mock_data.dart';
import '../data/institution_mock_data.dart';
import '../models/department.dart';
import '../models/institution_trend.dart';

final departmentsProvider = FutureProvider<List<Department>>((ref) {
  return mockDelay(() => DepartmentMockData.all);
});

final institutionKpisProvider = FutureProvider<List<InstitutionKpi>>((ref) {
  return mockDelay(() => InstitutionMockData.kpis());
});

final admissionTrendProvider = FutureProvider<List<YearlyMetric>>((ref) {
  return mockDelay(() => InstitutionMockData.admissionTrend);
});

final academicGrowthProvider = FutureProvider<List<YearlyMetric>>((ref) {
  return mockDelay(() => InstitutionMockData.academicGrowth);
});

final facultyGrowthProvider = FutureProvider<List<YearlyMetric>>((ref) {
  return mockDelay(() => InstitutionMockData.facultyGrowth);
});

final studentGrowthProvider = FutureProvider<List<YearlyMetric>>((ref) {
  return mockDelay(() => InstitutionMockData.studentGrowth);
});
