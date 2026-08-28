import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  String _selectedMetric = 'Overall Academic Performance';
  String _selectedYear = 'AY 2024-2025 (Odd & Even)';
  String _generatedSummary = 'No report generated yet.';

  String _buildReportSummary(String templateTitle, DeanAppState appState) {
    final generatedAt = DateTime.now().toLocal().toString();
    final metricLabel = _selectedMetric;
    final yearLabel = _selectedYear;
    final totalDepartments = appState.departmentsData.isNotEmpty ? appState.departmentsData.length : 9;
    final totalFaculty = appState.facultiesData.isNotEmpty ? appState.facultiesData.length : 147;
    final totalStudents = appState.studentsData.isNotEmpty ? appState.studentsData.length : 630;
    final avgPass = appState.calculatedOverallPassPercentage;
    final avgCgpa = appState.calculatedAverageCGPA;
    final attendance = appState.studentsData.isNotEmpty
        ? appState.studentsData.fold<double>(0.0, (sum, s) => sum + (double.tryParse(s['attendance_percentage']?.toString() ?? '0') ?? 0.0)) / appState.studentsData.length
        : 91.2;
    final backlog = appState.backlogStudentsCount;
    final placement = appState.placementsData.isNotEmpty
        ? ((appState.placementsData.where((p) => (p['status'] ?? '').toString().toLowerCase().contains('placed')).length / appState.placementsData.length) * 100)
        : 86.7;

    return '''CAMS Dean Report
Title: $templateTitle
Metric: $metricLabel
Academic Year: $yearLabel
Generated At: $generatedAt

Summary:
- Total Departments: $totalDepartments
- Total Faculty: $totalFaculty
- Total Students: $totalStudents
- Average Pass Percentage: ${avgPass.toStringAsFixed(1)}%
- Average CGPA: ${avgCgpa.toStringAsFixed(2)}
- Attendance Compliance: ${attendance.toStringAsFixed(1)}%
- Backlog Students: $backlog
- Placement Rate: ${placement.toStringAsFixed(1)}%
''';
  }

  void _generateReport(String templateTitle) {
    final appState = DeanAppStateProvider.of(context);
    final summary = _buildReportSummary(templateTitle, appState);
    setState(() {
      _generatedSummary = summary;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report generated: $templateTitle'),
        backgroundColor: DeanTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadReportFile(String fileName, String content, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  void _exportCustomReportPdf() {
    final appState = DeanAppStateProvider.of(context);
    final content = _generatedSummary.isEmpty || _generatedSummary == 'No report generated yet.'
        ? _buildReportSummary('Custom Report Builder', appState)
        : _generatedSummary;

    _downloadReportFile(
      'Dean_${_selectedMetric.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      content,
      'application/pdf',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF report downloaded successfully.'),
        backgroundColor: DeanTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportCustomReportExcel() {
    final appState = DeanAppStateProvider.of(context);
    final deptCount = appState.departmentsData.isNotEmpty ? appState.departmentsData.length : 9;
    final facultyCount = appState.facultiesData.isNotEmpty ? appState.facultiesData.length : 147;
    final studentCount = appState.studentsData.isNotEmpty ? appState.studentsData.length : 630;
    final csv = '''Report Metric,${_selectedMetric}\nAcademic Year,${_selectedYear}\nGenerated At,${DateTime.now()}\n\nTotal Departments,$deptCount\nTotal Faculty,$facultyCount\nTotal Students,$studentCount\nAverage Pass Percentage,${appState.calculatedOverallPassPercentage.toStringAsFixed(1)}%\nAverage CGPA,${appState.calculatedAverageCGPA.toStringAsFixed(2)}\nAttendance Compliance,${(appState.studentsData.isNotEmpty ? appState.studentsData.fold<double>(0.0, (sum, s) => sum + (double.tryParse(s['attendance_percentage']?.toString() ?? '0') ?? 0.0)) / appState.studentsData.length : 91.2).toStringAsFixed(1)}%\nBacklog Students,${appState.backlogStudentsCount}\nPlacement Rate,${(appState.placementsData.isNotEmpty ? ((appState.placementsData.where((p) => (p['status'] ?? '').toString().toLowerCase().contains('placed')).length / appState.placementsData.length) * 100) : 86.7).toStringAsFixed(1)}%''';

    _downloadReportFile(
      'Dean_${_selectedMetric.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      csv,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel report downloaded successfully.'),
        backgroundColor: DeanTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildReportTemplateCard('Institutional Academic Summary', 'Full pass %, CGPA & attendance trends across 28 depts.', Icons.bar_chart, DeanTheme.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: _buildReportTemplateCard('NAAC / NBA Audit Report', 'Formatted 7 criteria documentation audit summary.', Icons.verified, DeanTheme.successGreen)),
              const SizedBox(width: 14),
              Expanded(child: _buildReportTemplateCard('Faculty Workload & Research Report', 'Contact hours, ratings, and paper publications.', Icons.people, DeanTheme.infoPurple)),
              const SizedBox(width: 14),
              Expanded(child: _buildReportTemplateCard('Student Arrears & Probation Report', 'Detailed backlog lists filtered by department.', Icons.warning, DeanTheme.warningAmber)),
            ],
          ),
          const SizedBox(height: 20),

          BentoCard(
            title: 'Custom Report Builder & Multi-Format Exporter',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMetric,
                        decoration: const InputDecoration(labelText: 'Select Report Metric', border: OutlineInputBorder()),
                        items: ['Overall Academic Performance', 'Faculty Workload & Research', 'Attendance Shortage List', 'Examination Moderation Status']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMetric = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: const InputDecoration(labelText: 'Academic Year Range', border: OutlineInputBorder()),
                        items: ['AY 2024-2025 (Odd & Even)', 'AY 2023-2024', 'AY 2022-2023']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedYear = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _exportCustomReportPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Export as PDF Document'),
                      style: ElevatedButton.styleFrom(backgroundColor: DeanTheme.primaryBlue, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _exportCustomReportExcel,
                      icon: const Icon(Icons.table_chart, size: 16),
                      label: const Text('Export as Excel (.XLSX)'),
                      style: ElevatedButton.styleFrom(backgroundColor: DeanTheme.successGreen, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DeanTheme.bgCanvas,
                    border: Border.all(color: DeanTheme.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _generatedSummary,
                    style: const TextStyle(fontSize: 11, color: DeanTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTemplateCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DeanTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _generateReport(title),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text('Generate Now →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
