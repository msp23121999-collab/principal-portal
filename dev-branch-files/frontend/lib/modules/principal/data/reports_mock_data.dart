import '../models/report_item.dart';

/// Seed catalogue of exportable institutional reports.
class ReportsMockData {
  ReportsMockData._();

  static List<ReportItem> all() => [
    ReportItem(
      id: 'r01',
      title: 'Semester Result Summary',
      category: ReportCategory.academic,
      description: 'Pass percentage and grade distribution by department.',
      lastGeneratedAt: DateTime(2026, 7, 22),
    ),
    ReportItem(
      id: 'r02',
      title: 'Curriculum Compliance Report',
      category: ReportCategory.academic,
      description: 'Regulation and outcome-based education compliance status.',
      lastGeneratedAt: DateTime(2026, 7, 15),
    ),
    ReportItem(
      id: 'r03',
      title: 'Institution Attendance Summary',
      category: ReportCategory.attendance,
      description: 'Daily/weekly/monthly attendance rollup, institution-wide.',
      lastGeneratedAt: DateTime(2026, 7, 29),
    ),
    ReportItem(
      id: 'r04',
      title: 'Low Attendance Alert List',
      category: ReportCategory.attendance,
      description: 'Students below the minimum attendance threshold.',
      lastGeneratedAt: DateTime(2026, 7, 28),
    ),
    ReportItem(
      id: 'r05',
      title: 'Faculty Workload Report',
      category: ReportCategory.faculty,
      description: 'Weekly teaching load and course allocation per faculty.',
      lastGeneratedAt: DateTime(2026, 7, 20),
    ),
    ReportItem(
      id: 'r06',
      title: 'Faculty Research Output Report',
      category: ReportCategory.faculty,
      description: 'Published papers and research grants by department.',
      lastGeneratedAt: DateTime(2026, 7, 5),
    ),
    ReportItem(
      id: 'r07',
      title: 'Placement Season Summary',
      category: ReportCategory.placement,
      description: 'Companies visited, offers made, and package statistics.',
      lastGeneratedAt: DateTime(2026, 7, 25),
    ),
    ReportItem(
      id: 'r08',
      title: 'Department-Wise Placement Report',
      category: ReportCategory.placement,
      description: 'Placement percentage and average package by department.',
      lastGeneratedAt: DateTime(2026, 7, 18),
    ),
  ];
}
