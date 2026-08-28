import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class FacultyPerformanceScreen extends StatelessWidget {
  const FacultyPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final faculties = appState.facultiesData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workload Summary KPI Cards
          Row(
            children: [
              Expanded(child: _buildWorkloadKpiCard('Total Teaching Faculty', '${faculties.length}', 'Live from Supabase', Icons.people_outline, DeanTheme.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: _buildWorkloadKpiCard('Avg Contact Hours', '—', 'AICTE Standard: 16 hrs', Icons.access_time, DeanTheme.successGreen)),
              const SizedBox(width: 14),
              Expanded(child: _buildWorkloadKpiCard('Avg Feedback Rating', '—', 'Student Feedback System', Icons.star_outline, DeanTheme.warningAmber)),
              const SizedBox(width: 14),
              Expanded(child: _buildWorkloadKpiCard('Research Publications', '—', 'Scopus / Web of Science', Icons.article_outlined, DeanTheme.infoPurple)),
            ],
          ),
          const SizedBox(height: 20),

          // Faculty Performance Master Table
          BentoCard(
            title: 'Faculty Academic Performance & Research Output Table',
            child: faculties.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No faculty records found in Supabase (public.faculties).',
                        style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Emp ID & Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Workload (hrs)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Feedback Rating', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pass % (Subjects)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Papers Published', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: faculties.map((f) {
                        final id = (f['emp_id'] ?? f['employee_id'] ?? f['id'] ?? 'FAC').toString();
                        final name = (f['name'] ?? f['faculty_name'] ?? 'Faculty Member').toString();
                        final desig = (f['designation'] ?? 'Faculty').toString();
                        final dept = (f['department'] ?? f['department_code'] ?? '—').toString();
                        final hrs = (f['workload'] ?? '—').toString();
                        final rating = (f['rating'] ?? '—').toString();
                        final pass = (f['pass_percentage'] ?? '—').toString();
                        final papers = '${f['publications_count'] ?? 0} Papers';
                        return _buildFacultyRow(id, name, desig, dept, hrs, rating, pass, papers);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadKpiCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DeanTheme.cardBorder)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
                Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildFacultyRow(String id, String name, String desig, String dept, String hrs, String rating, String pass, String papers) {
    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(id, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
          ],
        )),
        DataCell(Text(desig, style: const TextStyle(fontSize: 12))),
        DataCell(Text(dept, style: const TextStyle(fontSize: 12))),
        DataCell(Text(hrs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Row(
          children: [
            const Icon(Icons.star, color: DeanTheme.warningAmber, size: 14),
            const SizedBox(width: 4),
            Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        )),
        DataCell(Text(pass, style: const TextStyle(color: DeanTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(4)),
          child: Text(papers, style: const TextStyle(color: Color(0xFF9333EA), fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}
