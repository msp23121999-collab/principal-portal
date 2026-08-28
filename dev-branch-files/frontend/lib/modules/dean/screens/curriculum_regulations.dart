import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class CurriculumRegulationsScreen extends StatelessWidget {
  const CurriculumRegulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final regulations = appState.regulationsData;

    if (appState.hasLoaded && regulations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No curriculum data is available yet. The Dean portal is waiting for live Supabase records.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: DeanTheme.textMuted),
          ),
        ),
      );
    }

    final rows = regulations.take(8).map((reg) {
      final code = (reg['code'] ?? reg['course_code'] ?? reg['regulation_code'] ?? 'N/A').toString();
      final title = (reg['title'] ?? reg['course_title'] ?? reg['name'] ?? 'Regulation').toString();
      final dept = (reg['department'] ?? reg['dept'] ?? 'Institution').toString();
      final sem = (reg['semester'] ?? reg['sem'] ?? 'All Semesters').toString();
      final credits = (reg['credits'] ?? reg['credit_points'] ?? '3').toString();
      final status = (reg['status'] ?? 'Approved').toString();
      final color = status.toLowerCase().contains('pending') || status.toLowerCase().contains('revision') ? DeanTheme.warningAmber : DeanTheme.successGreen;
      return _buildCourseRow(code, title, dept, sem, '3-0-0', credits, status, color);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRegulationCard('Regulation ${regulations.isNotEmpty ? (regulations.first['year'] ?? 'R2024') : 'R2024'}', 'Dean-managed curriculum and policy board', '${regulations.length} active records', 'Live from Supabase', DeanTheme.primaryBlue),
              const SizedBox(width: 16),
              _buildRegulationCard('Academic Rules & Governance', 'OBE / CBCS compliance monitoring', 'Audit ready', 'Syllabus & policy review', DeanTheme.successGreen),
            ],
          ),
          const SizedBox(height: 20),
          BentoCard(
            title: 'Curriculum, Regulation & BoS Compliance',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Course Code', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Course Title', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Semester', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('L-T-P', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Credits', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('BoS Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulationCard(String title, String sub, String credits, String batch, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(credits, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  child: Text(batch, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String code, String name, String credits, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol)),
          const SizedBox(height: 2),
          Text(credits, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  DataRow _buildCourseRow(String code, String title, String dept, String sem, String ltp, String credits, String status, Color statusCol) {
    return DataRow(
      cells: [
        DataCell(Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue))),
        DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(dept)),
        DataCell(Text(sem)),
        DataCell(Text(ltp)),
        DataCell(Text(credits, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: statusCol.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: statusCol, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}
