import 'package:flutter/material.dart';
import '../theme.dart';
import '../pdf_download_helper.dart';
import '../hod_toast.dart';
import '../responsive.dart';

class ReportsModuleView extends StatefulWidget {
  const ReportsModuleView({super.key});

  @override
  State<ReportsModuleView> createState() => _ReportsModuleViewState();
}

class _ReportsModuleViewState extends State<ReportsModuleView> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Breadcrumb
          HodSectionHeader(
            title: 'Department Analytics & Reports Hub',
            breadcrumb: 'Reports > Academic, Attendance, NAAC & Accreditation Reports',
            academicYear: 'Academic Year 2025 - 2026',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showGenerateCustomReportModal(context),
                icon: const Icon(Icons.note_add, size: 16, color: Colors.white),
                label: const Text('Generate Custom Report', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final crossAxisCount = (availableWidth / 220).floor().clamp(1, 4);
              final double itemHeight = 112.0;
              final double spacing = 8.0;
              final double itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
              final double aspectRatio = itemWidth / itemHeight;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: [
                  _buildKpiCard('Total Reports', '48', 'Available Reports', Icons.bar_chart, AppTheme.accentBlue),
                  _buildKpiCard('Scheduled Reports', '6', 'Auto Weekly PDF', Icons.schedule, AppTheme.accentGreen),
                  _buildKpiCard('Recent Generated', '12', 'Last 7 Days', Icons.history, AppTheme.accentPurple),
                  _buildKpiCard('NAAC / NBA Ready', '8', 'Accreditation Audits', Icons.workspace_premium, AppTheme.accentTeal),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Report Category Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactTab(
                  label: 'Faculty Workload',
                  icon: Icons.people,
                  isActive: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                _buildCompactTab(
                  label: 'Student Attendance',
                  icon: Icons.fact_check,
                  isActive: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),
                _buildCompactTab(
                  label: 'Academic Performance',
                  icon: Icons.school,
                  isActive: _activeTab == 2,
                  onTap: () => setState(() => _activeTab = 2),
                ),
                _buildCompactTab(
                  label: 'Course Completion',
                  icon: Icons.menu_book,
                  isActive: _activeTab == 3,
                  onTap: () => setState(() => _activeTab = 3),
                ),
                _buildCompactTab(
                  label: 'Research Output',
                  icon: Icons.science,
                  isActive: _activeTab == 4,
                  onTap: () => setState(() => _activeTab = 4),
                ),
                _buildCompactTab(
                  label: 'NAAC / NBA Accreditation',
                  icon: Icons.verified,
                  isActive: _activeTab == 5,
                  onTap: () => setState(() => _activeTab = 5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Report Catalog Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final crossAxisCount = availableWidth < 720 ? 1 : 2;
              final double itemHeight = 165.0;
              final double spacing = 14.0;
              final double itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
              final double aspectRatio = itemWidth / itemHeight;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: [
                  _buildReportCard(context, 'Faculty Workload & Teaching Hours Analysis', 'Comprehensive summary of teaching hours, lab duties, and BoS roles per faculty.', Icons.badge, AppTheme.accentBlue),
                  _buildReportCard(context, 'Department Student Attendance & Defaulters Log', 'Detailed section-wise student attendance % and <75% warning logs.', Icons.fact_check, AppTheme.accentGreen),
                  _buildReportCard(context, 'Internal Assessment & End Sem Pass Percentage', 'Pass percentage, SGPA/CGPA distribution, and subject-wise failure analysis.', Icons.grade, AppTheme.accentPurple),
                  _buildReportCard(context, 'NAAC Criterion 3 & 4 Accreditation Audit File', 'Official formatted report for NAAC research, infrastructure, and syllabus targets.', Icons.workspace_premium, AppTheme.accentOrange),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
            ],
          ),
          Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading Excel for "$title"...')));
                },
                icon: const Icon(Icons.table_chart, size: 14, color: Colors.green),
                label: const Text('Excel', style: TextStyle(fontSize: 11, color: Colors.green)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  PdfDownloadHelper.showExportConfirmation(context);
                },
                icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                label: const Text('PDF', style: TextStyle(fontSize: 11, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateCustomReportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Custom Department Report', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(decoration: InputDecoration(labelText: 'Report Title', hintText: 'e.g. Q2 Faculty Research & Attendance Audit')),
                SizedBox(height: 10),
                TextField(decoration: InputDecoration(labelText: 'Academic Year & Semester', hintText: '2025-26 • Semester IV')),
                SizedBox(height: 10),
                TextField(decoration: InputDecoration(labelText: 'Include Sections', hintText: 'Faculty, Students, NAAC, Research')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom Report generated and downloaded!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              child: const Text('Generate & Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
