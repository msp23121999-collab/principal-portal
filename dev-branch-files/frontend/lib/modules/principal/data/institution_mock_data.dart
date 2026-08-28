import '../models/institution_trend.dart';
import 'department_mock_data.dart';

/// Seed data for the Institution Analytics screen: multi-year trends and
/// top-level KPIs. Department composition is read from
/// [DepartmentMockData] rather than duplicated here.
class InstitutionMockData {
  InstitutionMockData._();

  static const List<YearlyMetric> admissionTrend = [
    YearlyMetric(year: '2021', value: 2650),
    YearlyMetric(year: '2022', value: 2820),
    YearlyMetric(year: '2023', value: 2990),
    YearlyMetric(year: '2024', value: 3105),
    YearlyMetric(year: '2025', value: 3250),
    YearlyMetric(year: '2026', value: 3410),
  ];

  static const List<YearlyMetric> academicGrowth = [
    YearlyMetric(year: '2021', value: 76.4),
    YearlyMetric(year: '2022', value: 78.9),
    YearlyMetric(year: '2023', value: 81.2),
    YearlyMetric(year: '2024', value: 83.5),
    YearlyMetric(year: '2025', value: 85.8),
    YearlyMetric(year: '2026', value: 87.6),
  ];

  static const List<YearlyMetric> facultyGrowth = [
    YearlyMetric(year: '2021', value: 168),
    YearlyMetric(year: '2022', value: 178),
    YearlyMetric(year: '2023', value: 191),
    YearlyMetric(year: '2024', value: 205),
    YearlyMetric(year: '2025', value: 214),
    YearlyMetric(year: '2026', value: 220),
  ];

  static const List<YearlyMetric> studentGrowth = [
    YearlyMetric(year: '2021', value: 2980),
    YearlyMetric(year: '2022', value: 3140),
    YearlyMetric(year: '2023', value: 3320),
    YearlyMetric(year: '2024', value: 3430),
    YearlyMetric(year: '2025', value: 3480),
    YearlyMetric(year: '2026', value: 3550),
  ];

  static List<InstitutionKpi> kpis() => [
    InstitutionKpi(
      label: 'Total Students',
      value: DepartmentMockData.totalStudents.toString(),
      trendPercent: '+4.8%',
      isPositive: true,
    ),
    InstitutionKpi(
      label: 'Total Faculty',
      value: DepartmentMockData.totalFaculty.toString(),
      trendPercent: '+2.9%',
      isPositive: true,
    ),
    const InstitutionKpi(
      label: 'Departments',
      value: '7',
      trendPercent: 'Stable',
      isPositive: true,
    ),
    InstitutionKpi(
      label: 'Avg. Attendance',
      value: '${DepartmentMockData.averageAttendance.toStringAsFixed(1)}%',
      trendPercent: '+1.2%',
      isPositive: true,
    ),
    InstitutionKpi(
      label: 'Avg. Placement',
      value: '${DepartmentMockData.averagePlacement.toStringAsFixed(1)}%',
      trendPercent: '+3.4%',
      isPositive: true,
    ),
    const InstitutionKpi(
      label: 'NIRF Ranking',
      value: '142',
      trendPercent: '+18 spots',
      isPositive: true,
    ),
  ];
}
